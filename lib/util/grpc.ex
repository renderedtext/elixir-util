defmodule Util.Grpc do

  @type client_name :: String.t()

  defmodule Client do
    defstruct :name, :endpoint, :timeout, :log_level, :publish_metrics

    @type t() :: {
      name: String.t(),
      endpoint: String.t(),
      timeout: number(),
      log_level: atom(),
      publish_metrics: boolean()
    }

    @default_timeout 30_000 # 30 seconds

    def new(name, endpoint), do: new(name, endpoint, @default_timeout, :info, true)
    def new(name, endpoint, timeout), do: new(name, endpoint, timeout, :info, true)

    def new(name, endpoint, timeout, log_level, publish_metrics) do
      %__MODULE__{
        name: name,
        endpoint: endpoint,
        timeout: timeout,
        log_level: log_level,
        publish_metrics: publish_metrics
      }
    end

    def do(client, callback) do
      Wormhole.capture(fn ->
        Watchman.benchmark("grpc.#{client.name}.duration", fn ->
          Watchman.increment("grpc.#{client.name}.connect")

          case Grpc.Stub.connect(client.endpoint) do
            {:ok, channel} ->
              callback.(channel)

            {:error, error} ->
              Logger.log(client.level, "Failed to connect to #{client.name} service err='#{inspect(error)}'")
              Watchman.increment("grpc.#{client.name}.connect.error")
          end
        end)
      end)
    end
  end

  def start_link do
    Util.Grpc.State.start_link()
  end

  @doc """
  Sets up Grpc connection information.

  Example:

    Util.Grpc.setup([
      Client.new(:service_a, Application.get_env("SERVICE_A_ENDPOINT"), :info, true)
      Client.new(:service_b, Application.get_env("SERVICE_B_ENDPOINT"), :info, true)
    ])

  """
  def setup(clients) do
    :ok = State.reset()

    Enum.each(clients, fn c -> Util.Grpc.State.add_client(c) end)

    :ok
  end

  @spec rpc(client_name(), GRPC.Channel.t(), function()) :: {:ok, any()} | {:error, :failed_to_connect, any()} | {:error, :timeout, any()} | {:error, any()}
  @doc """
  Executes a stateless RPC call to a remote service.

  1. It opens a new connection
  2. Sends the RPC request
  3. Waits for the result, or times out
  """
  def do(client_name, callback) do
    {:ok, client} = Agent.find(client_name)

    Client.rpc(client, callback)
  end

  end

  defmodule State do
    use Agent

    def start_link do
      Agent.start_link(fn -> %{} end, name: __MODULE__)
    end

    def reset do
      Agent.update(__MODULE__, %{})
    end
  end
end
