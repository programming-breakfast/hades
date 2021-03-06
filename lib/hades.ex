defmodule Hades do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    config = Application.get_env(:hades, Hades.Repo)
    unless Dict.has_key?(config, :database) do
      Dict.put(config, :database, System.get_env("DATABASE_PATH"))
    end
    Application.put_env(:hades, :souls_config_path, System.get_env("SOULS_CONFIG_PATH"))
    Application.put_env(:hades, Hades.Repo, config)

    children = [
      # Start the endpoint when the application starts
      supervisor(Hades.Endpoint, []),
      # Here you could define other workers and supervisors as children
      worker(Hades.Repo, []),
      worker(Hades.Styx, []),
      worker(Hades.Cerberus, []),
      worker(Hades.Empusa, [])
      # worker(Hades.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Hades.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    Hades.Endpoint.config_change(changed, removed)
    :ok
  end
end
