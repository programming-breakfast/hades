defmodule Hades.Cerberus do
  use GenServer
  import Logger

  alias Hades.Cerberus.Soul

  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  #
  # Client API
  #

  def list do
    GenServer.call(__MODULE__, :list)
  end

  def show(name) do
    GenServer.call(__MODULE__, {:show, name})
  end

  #
  # Server callbacks
  #

  def handle_call(:list, _from, state) do
    result = :ets.tab2list(__MODULE__)
    |> Enum.map(fn {_, _, soul} -> soul end)

    IO.inspect result

    {:reply, result, state}
  end

  def handle_call({:show, name}, _from, state) do
    [{_, _, soul} | _] = :ets.lookup(__MODULE__, name)
    {:reply, soul, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, message}, state) do
    [[soul] | _] = :ets.match(__MODULE__, {:'_', pid, :'$1'})
    Logger.warn "Soul #{soul.name} exited with #{inspect message}. Restarting."

    start_soul(soul)

    {:noreply, state}
  end


  def init(_) do
    config = [
      %Soul{name: "ping-ya", description: "foo description", start: "ping ya.ru"},
      %Soul{name: "ping-google", description: "foo description", start: "ping google.com"}
    ]

    init_ets

    start_souls(config)

    {:ok, %{}}
  end

  defp start_souls(config) do
    config
    |> Enum.each(&start_soul(&1))
  end

  @soul_startup_options [:monitor]

  defp start_soul(soul) do
    Logger.info "Starting external process #{soul.name}."

    soul = case :exec.run(String.to_char_list(soul.start), @soul_startup_options) do
      {:ok, pid, os_pid} ->
        %Soul{soul | os_pid: os_pid, pid: pid, state: :running, timer: 1}
      {_, _, _} ->
        %Soul{soul | state: :startup_error, timer: 1}
    end

    :ets.insert(__MODULE__, {soul.name, soul.pid, soul})
  end

  defp init_ets do
    :ets.new(__MODULE__, [:named_table])
  end
end
