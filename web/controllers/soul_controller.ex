defmodule Hades.SoulController do
  use Hades.Web, :controller

  def index(conn, _params) do
    render conn, "index.html", processes_list: Hades.Styx.list()
  end

  def show(conn, params) do
    render conn, "show.html", process: Hades.Styx.show(params["name"])
  end

  def stop(conn, params) do
    Hades.Cerberus.stop(params["name"])
    redirect conn, to: soul_path(conn, :index)
  end

  def start(conn, params) do
    Hades.Cerberus.start(params["name"])
    redirect conn, to: soul_path(conn, :index)
  end
end
