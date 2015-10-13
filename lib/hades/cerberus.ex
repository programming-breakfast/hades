defmodule Hades.Cerberus do
  use GenServer
  import Logger

  alias Hades.Soul
  alias Hades.Styx
  alias Hades.Empusa

  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_) do
    Styx.list() |> Enum.each(&async_start_soul(&1))
    spawn_link fn -> check_soul_resourses() end
    {:ok, %{}}
  end

  #
  # Client API
  #

  def stop(name) do
    GenServer.call(__MODULE__, {:stop, name})
  end

  def start(name) do
    GenServer.call(__MODULE__, {:start, name})
  end

  def restart(name) do
    GenServer.call(__MODULE__, {:restart, name})
  end

  def manage(name) do
    GenServer.call(__MODULE__, {:manage, name})
  end

  #
  # Server callbacks
  #

  def handle_call({:stop, name}, _from, state) do
    soul = Styx.find(name)
    if soul.state == :running do
      stop_soul(soul, false)
    else
      Logger.warn("You can stop only running process '#{soul.name}'")
    end
    {:reply, soul, state}
  end

  def handle_call({:restart, name}, _from, state) do
    soul = Styx.find(name)

    case soul.state do
      :running ->
        stop_soul(soul, true)
      :stopped ->
        async_start_soul(soul)
      _ ->
        Logger.warn("You can restart only stopped or running process '#{soul.name}'")
    end

    {:reply, soul, state}
  end

  def handle_call({:start, name}, _from, state) do
    soul = Styx.find(name)
    Logger.info "start process #{inspect soul}"
    case soul.state do
      :stopped ->
        async_start_soul(soul)
      _ ->
        Logger.warn("You can start only stopped process '#{soul.name}'")
    end
    {:reply, soul, state}
  end

  def handle_call({:manage, name}, _from, state) do
    soul = Styx.find(name)
    Logger.info "manage process #{inspect soul}"
    case soul.state do
      :trying_to_run ->
        manage_soul(soul)
      _ ->
        Logger.warn("You can manage only pre runned process '#{soul.name}'")
    end
    {:reply, soul, state}
  end

  def handle_info({:DOWN, _ref, :process, pid, message}, state) do
    soul = Styx.find(pid)
    if !is_nil(soul) do
      Styx.update(soul.name, %{state: :stopped, os_pid: nil, pid: nil, metrics: nil})
      File.rm(soul.pid_file)
      case soul.state do
        :trying_to_stop ->
          Logger.warn "Soul #{soul.name} successfully stopped."
        :trying_to_restart ->
          async_start_soul(soul)
        _ ->
          Logger.warn "Soul #{soul.name} exited with #{inspect message}. Restarting."
          async_start_soul(soul)
      end
    end

    {:noreply, state}
  end

  #
  # Private
  #

  defp check_soul_resourses do
    :timer.sleep(2000)
    metrics = Empusa.metrics()
    Styx.list()
    |> Enum.each(fn soul ->
      if Dict.has_key?(metrics, soul.name) do
        if soul.memory_limit && metrics[soul.name]["memory_rss"] > soul.memory_limit do
          Logger.warn "Soul #{soul.name} exceed memory limit #{soul.memory_limit} Mb. Restarting."
          __MODULE__.restart(soul.name)
        end
      end
    end)
    check_soul_resourses()
  end

  @soul_startup_options [:monitor]
  @stop_timeout 60

  defp soul_startup_options(soul) do
    kill_options = case soul.stop do
      nil ->
        []
      stop_command ->
        [{:kill, String.to_char_list(stop_command)}]
    end

    kill_options ++ [{:kill_timeout, (soul.stop_timeout || @stop_timeout)}] ++ @soul_startup_options
  end

  defp manage_soul(soul) do
    {:ok, os_pid_str} = File.read(soul.pid_file)
    {os_pid, _} = Integer.parse(os_pid_str)

    case :exec.manage(os_pid, soul_startup_options(soul)) do
      {:ok, pid, os_pid} ->
        Styx.update(soul.name, %{os_pid: os_pid, pid: pid, state: :running})
      {:error, :not_found} ->
        Logger.warn("Startup error with managing #{soul.name}: process with PID##{os_pid} does NOT exist")
        if File.rm(soul.pid_file) == :ok do
          run_soul(soul)
        end
    end
  end

  defp run_soul(soul) do
    case :exec.run(String.to_char_list(String.replace(soul.start, "%pid_file%", soul.pid_file || "")), [:sync]) do
      {:ok, _} ->
        __MODULE__.manage(soul.name)
      {s, reason} ->
        Logger.warn("Startup error with #{soul.name} caz 1. #{inspect s} and 2. #{inspect reason}")
        Styx.update(soul.name, %{state: :stopped})
    end
  end

  defp async_start_soul(soul) do
    spawn_link fn -> start_soul(soul) end
  end

  defp start_soul(soul) do
    Logger.info "Starting external process #{soul.name} with suct options: #{inspect soul_startup_options(soul)}."
    Styx.update(soul.name, %{state: :trying_to_run})
    if File.exists?(soul.pid_file) do
      manage_soul(soul)
    else
      run_soul(soul)
    end
  end

  defp stop_soul(soul, restart) do
    state = if restart do
      :trying_to_restart
    else
      :trying_to_stop
    end

    Styx.update(soul.name, %{state: state})
    spawn_link fn ->
      :exec.stop_and_wait(soul.pid, (soul.stop_timeout || @stop_timeout) * 2)
      File.rm(soul.pid_file)
    end
  end
end
