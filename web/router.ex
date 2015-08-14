defmodule Hades.Router do
  use Hades.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", Hades do
    pipe_through :browser # Use the default browser stack

    get "/", SoulController, :index
    get "/souls/:name", SoulController, :show

    get "/souls/:name/start", SoulController, :start
    get "/souls/:name/stop", SoulController, :stop
  end

  # Other scopes may use custom stacks.
  # scope "/api", Hades do
  #   pipe_through :api
  # end
end
