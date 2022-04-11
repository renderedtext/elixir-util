defmodule Util.GrpcX.Client do
  require Logger

  alias Util.GrpcX.RPCCall

  @enforce_keys [:name, :endpoint, :timeout, :log_level, :publish_metrics, :stub]

  defstruct @enforce_keys

  @type t() :: %__MODULE__{
          name: String.t(),
          endpoint: String.t(),
          timeout: number(),
          log_level: atom(),
          publish_metrics: boolean(),
          stub: Grpc.Stub.t()
        }

  # 30 seconds
  @default_timeout 30_000
  @default_log_level :info

  def new(name, endpoint, stub, opts \\ []) do
    timeout = Keyword.get(opts, :timeout, @default_timeout)
    log_level = Keyword.get(opts, :log_level, @default_log_level)
    publish_metrics = Keyword.get(opts, :publish_metrics, true)

    %__MODULE__{
      name: name,
      endpoint: endpoint,
      timeout: timeout,
      log_level: log_level,
      stub: stub,
      publish_metrics: publish_metrics
    }
  end

  @spec call(Client.t(), atom(), any, any) :: {:ok, any} | {:error, any}
  def call(client, method_name, request, opts \\ []) do
    rpc_call = RPCCall.new(client, method_name, request, opts)

    Wormhole.capture(fn -> RPCCall.execute(rpc_call) end, timeout: rpc_call.timeout)
  end
end
