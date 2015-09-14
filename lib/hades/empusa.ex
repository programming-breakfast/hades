defmodule Hades.Empusa do
  use GenServer
  import Logger

  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  def init(_) do
    spawn_link fn -> update_metrics() end

    {:ok, %{}}
  end

  def update_metrics do
    :timer.sleep(1000)
    result_metrics = Hades.Cerberus.list()
    |> Enum.filter(fn soul -> soul.os_pid end)
    |> Enum.map(fn soul -> soul.os_pid end) |> metrics
    case result_metrics do
      {:ok, result} ->
        Hades.Cerberus.update_metrics(result)
      {:error, reason} ->
        Logger.warn("Failed to retrive data bacause of #{reason}")
    end

    update_metrics()
  end

  def metrics(pids) do
    try do
      response = HTTPotion.get "http://localhost:8000/status?pids=#{Enum.join(pids, ",")}"
      JSX.decode(response.body)
    rescue
      _error ->
        {:error, :failed_to_connect}
    end
  end
end
