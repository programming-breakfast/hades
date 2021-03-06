defmodule Hades.Mixfile do
  use Mix.Project

  def project do
    [app: :hades,
     version: "0.0.2",
     elixir: "~> 1.0",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  # Configuration for the OTP application
  #
  # Type `mix help compile.app` for more information
  def application do
    [mod: {Hades, []},
     env: [souls_config_path: nil],
     applications: [
       :phoenix,
       :phoenix_html,
       :phoenix_ecto,
       :sqlite_ecto,
       :cowboy,
       :logger,
       :runtime_tools,
       :sqlitex,
       :exec,
       :ibrowse,
       :erlport,
       :exjsx,
       :porcelain,
       :tzdata,
       :timex,
       :ini,
       :httpotion
     ]]
  end

  # Specifies which paths to compile per environment
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  # Specifies your project dependencies
  #
  # Type `mix help deps` for examples and options
  defp deps do
    [{:phoenix, "~> 1.0.0"},
     {:phoenix_html, "~> 2.1"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:phoenix_ecto, "~> 1.1"},
     {:sqlite_ecto, ">= 0.0.0"},
     {:cowboy, "~> 1.0"},
     {:exec, github: "saleyn/erlexec"},
     {:porcelain, "~> 2.0"},
     {:ibrowse, github: "cmullaparthi/ibrowse", tag: "v4.1.2"},
     {:httpotion, "~> 2.1.0"},
     {:timex, "~> 0.19.4"},
     {:exrm, "0.19.9"},
     {:ini, "0.0.1"},
     {:erlport, git: "https://github.com/hdima/erlport.git"},
     {:exjsx, github: "talentdeficit/exjsx"}
    ]
  end
end
