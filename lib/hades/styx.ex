defmodule Hades.Styx do
  use GenServer
  import Logger

  alias Hades.Soul

  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_) do
    config = [
      %Soul{name: "foo", start: "while true; do sleep 1; done & echo $! > %pid_file%", pid_file: "tmp/foo.pid"},
      %Soul{name: "bar", start: "while true; do sleep 2; done & echo $! > %pid_file%", stop: "kill -9 `cat tmp/bar.pid`", pid_file: "tmp/bar.pid"}
    ]

    :ets.new(__MODULE__, [:named_table, :set])

    config |> Enum.each(&insert_soul(&1))

    {:ok, %{}}
  end

  #
  # Client API
  #

  def list do
    GenServer.call(__MODULE__, :list)
  end

  def update(soul_id, soul_attrs) do
    GenServer.call(__MODULE__, {:update, soul_id, soul_attrs})
  end

  def find(criteria) do
    GenServer.call(__MODULE__, {:find, criteria})
  end

  #
  # Server callbacks
  #

  def handle_call(:list, _from, state) do
    {:reply, soul_list(), state}
  end

  def handle_call({:update, soul_id, soul_attrs}, _from, state) do
    {:reply, update_soul(soul_id, soul_attrs), state}
  end

  def handle_call({:find, criteria}, _from, state) do
    {:reply, find_soul(criteria), state}
  end

  #
  # Private
  #

  defp soul_list do
    :ets.tab2list(__MODULE__) |> Enum.map(fn {_, _, soul} -> soul end)
  end

  defp update_soul(soul_id, soul_attrs) do
    updated_soul = find_soul(soul_id) |> Map.merge(soul_attrs)
    insert_soul(updated_soul)
    updated_soul
  end

  defp find_soul(criteria) when is_pid(criteria) do
    case :ets.match(__MODULE__, {:'_', criteria, :'$1'}) do
      [] ->
        nil
      [[soul] | _] ->
        soul
    end
  end

  defp find_soul(criteria) do
    [[soul] | _] = :ets.match(__MODULE__, {criteria, :'_', :'$1'})
    soul
  end

  defp insert_soul(soul) do
    :ets.insert(__MODULE__, {soul.name, soul.pid, soul})
  end
end
