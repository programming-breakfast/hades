defmodule Hades.Empusa do
  use GenServer
  import Logger

  alias Hades.ProcessInfo

  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_) do
    spawn_link fn -> update_state_metrics() end
    # spawn_link fn -> record_metrics_to_db() end

    {:ok, %{}}
  end

  def metrics do
    GenServer.call(__MODULE__, :metrics)
  end

  def update_metrics(metrics) do
    GenServer.call(__MODULE__, {:update_metrics, metrics})
  end

  def handle_call(:metrics, _from, state) do
    {:reply, state, state}
  end

  def handle_call({:update_metrics, metrics}, _from, state) do
    {:reply, metrics, metrics}
  end

  defp update_state_metrics do
    :timer.sleep(1000)
    result_metrics = Hades.Styx.list()
    |> Enum.filter(fn soul -> soul.os_pid end)
    |> Enum.map(fn soul -> soul.os_pid end)
    |> metrics

    case result_metrics do
      {:ok, result} ->
        Hades.Styx.list()
        |> Enum.filter(fn soul -> !!soul.os_pid && Map.has_key?(result, Integer.to_string(soul.os_pid)) end)
        |> Enum.reduce(%{}, fn soul, acc ->
          os_pid = Integer.to_string(soul.os_pid)
          Map.put(acc, soul.name, %{
            "name" => soul.name,
            "created_at" => Timex.Date.from(result[os_pid]["created_at"], :secs),
            "cpu_user" => result[os_pid]["cpu"]["user"],
            "cpu_system" => result[os_pid]["cpu"]["system"],
            "cpu_percent" => result[os_pid]["cpu"]["percent"],
            "memory_pageins" => result[os_pid]["memory"]["pageins"],
            "memory_pfaults" => result[os_pid]["memory"]["pfaults"],
            "memory_rss" => result[os_pid]["memory"]["rss"],
            "memory_vms" => result[os_pid]["memory"]["vms"]
            })
        end)
        |> __MODULE__.update_metrics
      {:error, reason} ->
        Logger.warn("Failed to retrive data bacause of #{reason}")
    end

    update_state_metrics()
  end

  defp record_metrics_to_db do
    :timer.sleep(1000 * 5)
    __MODULE__.metrics()
    |> Dict.values
    |> Enum.each(fn process_info ->
      ProcessInfo.changeset(%ProcessInfo{}, process_info)
      |> Hades.Repo.insert
    end)

    record_metrics_to_db()
  end

  defp metrics(pids) do
    try do
      {:ok, pp} = :python.start_link()
      metrics = :python.call(pp, :monitoring, :collect, [pids]) |> JSX.decode
      :python.stop(pp)
      metrics
    rescue
      _error ->
        {:error, :failed_to_run}
    end
  end
end
