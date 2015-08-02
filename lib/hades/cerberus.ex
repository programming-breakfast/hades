defmodule Hades.Cerberus do
  use GenServer

  def start_link(opts \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, [], opts)
  end

  #
  # Client API
  #

  def list do
    GenServer.call(__MODULE__, :list)
  end

  def show(name) do
    GenServer.call(__MODULE__, {:show, name})
  end

  #
  # Server callbacks
  #

  def handle_call(:list, _from, state) do
    result = %{name: "HEY, MAMA!"}
    {:reply, result, state}
  end

  def handle_call({:show, name}, _from, state) do
    result = state[:processes][name]

    {:reply, result, state}
  end


  def init(_) do
    state = HashDict.new
      |> Dict.put(
           :processes,
           %{"foo" =>
           %{name: "foo", description: "foo description"}
         })

    {:ok, state}
  end
end
