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

  def stop(name) do
    GenServer.call(__MODULE__, {:stop, name})
  end

  def start(name) do
    GenServer.call(__MODULE__, {:start, name})
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

  def handle_call({:stop, name}, _from, state) do
    [{_, _, soul} | _] = :ets.lookup(__MODULE__, name)
    stop_soul(soul)
    {:reply, soul, state}
  end

  def handle_call({:start, name}, _from, state) do
    [{_, _, soul} | _] = :ets.lookup(__MODULE__, name)
    start_soul(soul)
    {:reply, soul, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, message}, state) do
    soul = find_soul(pid)
    Logger.warn "Soul #{inspect soul} down."
    case soul.state do
      :trying_to_stop ->
        Logger.warn "Soul #{soul.name} successfully stopped."
        update_soul(soul, %{state: :stopped, os_pid: nil, pid: nil})
      _ ->
        Logger.warn "Soul #{soul.name} exited with #{inspect message}. Restarting."
        start_soul(soul)
    end

    {:noreply, state}
  end


  def init(_) do
    config = [
      %Soul{name: "ping-ya", description: "foo description", start: "ping ya.ru"},
      %Soul{name: "ping-google", description: "foo description", start: "ping google.ru"}
    ]

    init_ets

    start_souls(config)

    {:ok, %{}}
  end

  defp find_soul(criteria) when is_pid(criteria) do
    [[soul] | _] = :ets.match(__MODULE__, {:'_', criteria, :'$1'})
    soul
  end

  defp find_soul(criteria) do
    [[soul] | _] = :ets.match(__MODULE__, {criteria, :'_', :'$1'})
    soul
  end

  defp start_souls(config) do
    config
    |> Enum.each(&start_soul(&1))
  end

  @soul_startup_options [:monitor]

  defp soul_startup_options(soul) do
    startup_options = case soul.stop do
      nil ->
        []
      stop_command ->
        [{:kill, String.to_char_list(stop_command)}]
    end

    startup_options ++ @soul_startup_options
  end

  defp start_soul(soul) do
    Logger.info "Starting external process #{soul.name} with suct options: #{inspect soul_startup_options(soul)}."
    case :exec.run(String.to_char_list(soul.start), soul_startup_options(soul)) do
      {:ok, pid, os_pid} ->
        update_soul(soul, %{os_pid: os_pid, pid: pid, state: :running, timer: 1})
      {_, _, _} ->
        update_soul(soul, %{state: :startup_error, timer: 1})
    end
  end

  defp stop_soul(soul) do
    update_soul(soul, %{state: :trying_to_stop})
    :exec.stop(soul.pid)
  end

  defp update_soul(soul, soul_attrs) do
    updated_soul = Map.merge(soul, soul_attrs)
    :ets.insert(__MODULE__, {updated_soul.name, updated_soul.pid, updated_soul})
  end

  defp init_ets do
    :ets.new(__MODULE__, [:named_table])
  end
end
