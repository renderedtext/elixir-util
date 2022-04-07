defmodule Util.Grpc.State do
  use Agent

  @moduledoc """
  Keeps the configuration state for every Grcp client.

  Example usage:

    State.add_client(Client.new(name: "service1", endpoint: "localhost:9000", ...))
    State.find_client("service1") => %Client{}

  """

  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def add_client(client) do
    Agent.update(__MODULE__, fn state -> Map.put(state, client.name, client) end)
  end

  def find_client(name) do
    Agent.get(__MODULE__, fn state -> Map.fetch!(state, name) end)
  end

  def reset do
    Agent.update(__MODULE__, %{})
  end
end
