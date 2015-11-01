defmodule Hades.SoulController do
  use Hades.Web, :controller
  import Logger

  def index(conn, _params) do
    render conn, "index.html",
    processes_list: Hades.Styx.list() |> Enum.sort_by(fn(soul) -> soul.name end),
    metrics: Hades.Empusa.metrics(),
    processes_groups: Hades.Styx.group_names_list()
  end

  def show(conn, params) do
    render conn, "show.html", process: Hades.Styx.find(params["name"])
  end

  def stop(conn, params) do
    Hades.Cerberus.stop(params["name"])
    redirect conn, to: soul_path(conn, :index)
  end

  def start(conn, params) do
    Hades.Cerberus.start(params["name"])
    redirect conn, to: soul_path(conn, :index)
  end

  def restart(conn, params) do
    Hades.Cerberus.restart(params["name"])
    redirect conn, to: soul_path(conn, :index)
  end

  def group_action(conn, params) do
    Hades.Cerberus.group_action(String.to_atom(params["group_action"]), params["name"])
    redirect conn, to: soul_path(conn, :index)
  end
end
