defmodule Hades.ProcessController do
  use Hades.Web, :controller

  def index(conn, _params) do
    render conn, "index.html", processes_list: Hades.Cerberus.list()
  end

  def show(conn, params) do
    render conn, "show.html", process: Hades.Cerberus.show(params["name"])
  end
end
