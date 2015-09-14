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

  def update_metrics(metrics) do
    GenServer.call(__MODULE__, {:update_metrics, metrics})
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
    {:reply, soul_list(), state}
  end

  defp soul_list do
    :ets.tab2list(__MODULE__)
    |> Enum.map(fn {_, _, soul} -> soul end)
  end

  def handle_call({:update_metrics, metrics}, _from, state) do
    soul_list() |> Enum.each(fn(soul) ->
      if soul.os_pid && Dict.has_key?(metrics, Integer.to_string(soul.os_pid)) do
        update_soul(soul, %{metrics: Dict.get(metrics, Integer.to_string(soul.os_pid))})
      else
        update_soul(soul, %{metrics: nil})
      end
    end)
    {:reply, nil, state}
  end

  def handle_call({:show, name}, _from, state) do
    [{_, _, soul} | _] = :ets.lookup(__MODULE__, name)
    {:reply, soul, state}
  end

  def handle_call({:stop, name}, _from, state) do
    [{_, _, soul} | _] = :ets.lookup(__MODULE__, name)
    if soul.state == :running do
      stop_soul(soul)
    else
      Logger.warn("You can stop only running process '#{soul.name}'")
    end
    {:reply, soul, state}
  end

  def handle_call({:start, name}, _from, state) do
    [{_, _, soul} | _] = :ets.lookup(__MODULE__, name)
    Logger.info "start process #{inspect soul}"
    case soul.state do
      :stopped ->
        start_soul(soul)
      _ ->
        Logger.warn("You can start only stopped process '#{soul.name}'")
    end
    {:reply, soul, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, message}, state) do
    soul = find_soul(pid)
    if !is_nil(soul) do
      update_soul(soul, %{state: :stopped, os_pid: nil, pid: nil, metrics: nil})
      File.rm(soul.pid_file)
      case soul.state do
        :trying_to_stop ->
          Logger.warn "Soul #{soul.name} successfully stopped."
        _ ->
          Logger.warn "Soul #{soul.name} exited with #{inspect message}. Restarting."
          start_soul(soul)
      end
    end

    {:noreply, state}
  end

  def init(_) do
    config = [
      %Soul{name: "metrics", start: "python3 mon/ps_monitoring.py & echo $! > %pid_file%", pid_file: "tmp/metrics.pid"},
      %Soul{name: "foo", start: "while true; do sleep 1; done & echo $! > %pid_file%", pid_file: "tmp/foo.pid"},
      %Soul{name: "bar", start: "while true; do sleep 2; done & echo $! > %pid_file%", stop: "kill -9 `cat tmp/bar.pid`", pid_file: "tmp/bar.pid"}
    ]

    init_ets

    config |> Enum.each(&start_soul(&1))

    {:ok, %{}}
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
    case :exec.run(String.to_char_list(String.replace(soul.start, "%pid_file%", soul.pid_file || "")), [:sync]) do
      {:ok, _} ->
        {:ok, os_pid_str} = File.read(soul.pid_file)
        {os_pid, _} = Integer.parse(os_pid_str)
        {:ok, pid, os_pid} = :exec.manage(os_pid, soul_startup_options(soul))
        update_soul(soul, %{os_pid: os_pid, pid: pid, state: :running, timer: 1})
      {s, reason} ->
        Logger.warn("Startup error with #{soul.name} caz 1. #{inspect s} and 2. #{inspect reason}")
        update_soul(soul, %{state: :stopped, timer: 1})
    end
  end

  defp stop_soul(soul) do
    update_soul(soul, %{state: :trying_to_stop})
    case soul.stop do
      nil ->
        :exec.stop(soul.pid)
      stop_command ->
        Logger.info("Stop with #{stop_command}")
        :exec.run(String.to_char_list(stop_command), [])
    end
  end

  defp update_soul(soul, soul_attrs) do
    Logger.warn("Update soul##{soul.name} with #{inspect soul_attrs}")
    updated_soul = Map.merge(soul, soul_attrs)
    :ets.insert(__MODULE__, {updated_soul.name, updated_soul.pid, updated_soul})
  end

  defp init_ets do
    :ets.new(__MODULE__, [:named_table])
  end
end
