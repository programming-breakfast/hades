defmodule Hades.Cerberus do
  use GenServer
  import Logger

  alias Hades.Soul
  alias Hades.Styx

  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_) do
    Styx.list() |> Enum.each(&start_soul(&1))
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

  #
  # Server callbacks
  #

  def handle_call({:stop, name}, _from, state) do
    soul = Styx.find(name)
    if soul.state == :running do
      stop_soul(soul)
    else
      Logger.warn("You can stop only running process '#{soul.name}'")
    end
    {:reply, soul, state}
  end

  def handle_call({:start, name}, _from, state) do
    soul = Styx.find(name)
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
    soul = Styx.find(pid)
    if !is_nil(soul) do
      Styx.update(soul.name, %{state: :stopped, os_pid: nil, pid: nil, metrics: nil, created_at: nil})
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

  #
  # Private
  #

  @soul_startup_options [:monitor]

  defp os_pid_from(pid_file) do
    {:ok, os_pid_str} = File.read(pid_file)
    {os_pid, _} = Integer.parse(os_pid_str)
    os_pid
  end

  defp start_soul_from_pid_file(soul) do
    os_pid = os_pid_from(soul.pid_file)
    case :exec.manage(os_pid, @soul_startup_options) do
      {:ok, pid, os_pid} ->
        Styx.update(soul.name, %{os_pid: os_pid, pid: pid, state: :running, created_at: nil})
      {:error, :not_found} ->
        Logger.warn("Startup error with managing #{soul.name}: process with PID##{os_pid} does NOT exist")
        # File.rm(soul.pid_file)
        # start_soul(soul)
    end
  end

  defp start_soul(soul) do
    Logger.info "Starting external process #{soul.name} with suct options: #{inspect @soul_startup_options}."
    if File.exists?(soul.pid_file) do
      start_soul_from_pid_file(soul)
    else
      case :exec.run(String.to_char_list(String.replace(soul.start, "%pid_file%", soul.pid_file || "")), [:sync]) do
        {:ok, _} ->
          start_soul_from_pid_file(soul)
        {s, reason} ->
          Logger.warn("Startup error with executing #{soul.name} caz 1. #{inspect s} and 2. #{inspect reason}")
      end
    end
  end

  defp stop_soul(soul) do
    Styx.update(soul.name, %{state: :trying_to_stop})
    case soul.stop do
      nil ->
        :exec.stop(soul.pid)
      stop_command ->
        Logger.info("Stop with #{stop_command}")
        :exec.run(String.to_char_list(stop_command), [])
    end
  end
end
