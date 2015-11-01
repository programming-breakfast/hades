defmodule Hades.Styx do
  use GenServer
  import Logger

  alias Hades.Soul

  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_) do
    :ets.new(__MODULE__, [:named_table, :set])

    {:ok, ini} = File.read(Application.get_env(:hades, :souls_config_path))

    Ini.decode(ini)
    |> prepare_ini_params
    |> Enum.map(fn conf-> Map.merge(%Soul{}, conf) end)
    |> Enum.each(&insert_soul(&1))

    {:ok, %{}}
  end

  #
  # Client API
  #

  def list do
    GenServer.call(__MODULE__, :list)
  end

  def group_names_list do
    GenServer.call(__MODULE__, :group_names_list)
  end

  def update(soul_id, soul_attrs) do
    GenServer.call(__MODULE__, {:update, soul_id, soul_attrs})
  end

  def find(criteria) do
    GenServer.call(__MODULE__, {:find, criteria})
  end

  def find_by_group(group_name) do
    GenServer.call(__MODULE__, {:find_by_group, group_name})
  end

  #
  # Server callbacks
  #

  def handle_call(:list, _from, state) do
    {:reply, soul_list(), state}
  end

  def handle_call(:group_names_list, _from, state) do
    group_names = soul_list()
    |> Enum.reduce(HashSet.new, fn(soul, acc) -> Set.union(soul.groups || HashSet.new, acc) end)
    |> Enum.sort
    {:reply, group_names, state}
  end

  def handle_call({:update, soul_id, soul_attrs}, _from, state) do
    {:reply, update_soul(soul_id, soul_attrs), state}
  end

  def handle_call({:find, criteria}, _from, state) do
    {:reply, find_soul(criteria), state}
  end

  def handle_call({:find_by_group, group_name}, _from, state) do
    souls = soul_list()
    |> Enum.filter(fn(soul)-> soul.groups && Set.member?(soul.groups, group_name) end)
    {:reply, souls, state}
  end

  #
  # Private
  #

  defp prepare_ini_params(souls_config) do
    processing_map = %{
      :stop_timeout => &(String.to_integer(&1[:stop_timeout])),
      :memory_limit => &(String.to_integer(&1[:memory_limit])),
      :groups => &(Enum.into(String.split(&1[:groups], ","), HashSet.new)),
      :start => &(String.replace(&1[:start], "%pid_file%", &1[:pid_file] || "")),
      :stop => &(String.replace(&1[:stop], "%pid_file%", &1[:pid_file] || ""))
    }

    souls_config
    |> Enum.map (fn {name, data} ->
      Dict.put(data, :name, Atom.to_string(name))
      |> Enum.reduce(%{}, fn {k,v}, accum ->
        if Dict.has_key?(processing_map, k) do
          new_value = Dict.get(processing_map, k).(data)
        else
          new_value = v
        end

        Dict.put(accum, k, new_value)
      end)
    end)
  end

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
