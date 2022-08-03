defmodule Util.GrpcX.State do
  use Agent

  def start_link(clients) do
    state =
      clients
      |> Enum.map(fn c -> {c.name, c} end)
      |> Enum.into(%{})

    Agent.start_link(fn -> state end, name: __MODULE__)
  end

  def find_client(name) do
    state = Agent.get(__MODULE__, &Function.identity/1)

    Map.fetch(state, name)
  end
end
