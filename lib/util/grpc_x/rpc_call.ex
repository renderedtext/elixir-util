defmodule Util.GrpcX.RPCCall do
  require Logger

  @type response ::
          {:ok, any()}
          | {:error, :failed_to_connect, any()}
          | {:error, :timeout, any()}
          | {:error, any()}

  def new(client, method_name, request, opts) do
    default_call_opts = [timeout: client.timeout]
    call_opts = Keyword.merge(default_call_opts, opts)

    %{
      endpoint: client.endpoint,
      client_name: client.name,
      stub: client.stub,
      method_name: method_name,
      request: request,
      log_level: client.log_level,
      opts: call_opts,
      publish_metrics: client.publish_metrics,
      metric_prefix: "grpc.#{client.name}.#{method_name}",
      timeout: client.timeout
    }
  end

  @spec execute(RPRCall.t()) :: response()
  def execute(rpc_call) do
    benchmark(rpc_call, fn ->
      with {:ok, channel} <- connect(rpc_call) do
        result = send_req(rpc_call, channel)

        disconnect(channel)

        result
      end
    end)
  end

  defp connect(rpc) do
    inc(rpc, "connect.count")

    case GRPC.Stub.connect(rpc.endpoint) do
      {:ok, channel} ->
        {:ok, channel}

      {:error, err} ->
        inc(rpc, "connect.error.count")
        log_err(rpc, "failed to connect to #{rpc.endpoint}")

        {:error, err}
    end
  end

  defp disconnect(channel) do
    GRPC.Stub.disconnect(channel)
  end

  defp send_req(rpc, channel) do
    inc(rpc, "request.count")

    case do_call(rpc, channel) do
      {:ok, result} ->
        inc(rpc, "response.success.count")
        {:ok, result}

      {:error, {:unknown_rpc, _}} = e ->
        e

      {:error, err} ->
        inc(rpc, "response.error.count")
        log_err(rpc, "err='#{inspect(err)}'")

        {:error, err}
    end
  end

  defp do_call(rpc, channel) do
    # todo handle middlewares

    apply(rpc.stub, rpc.method_name, [channel, rpc.request, rpc.opts])
  rescue
    e in UndefinedFunctionError ->
      {:error, {:unknown_rpc, "no RPC method named='#{e.function}'"}}
  end

  defp inc(rpc, metric) do
    if rpc.publish_metrics do
      Watchman.increment("#{rpc.metric_prefix}.#{metric}")
    end
  end

  defp benchmark(rpc, cb) do
    if rpc.publish_metrics do
      Watchman.benchmark("#{rpc.metric_prefix}.duration", cb)
    else
      cb.()
    end
  end

  defp log_err(rpc, msg) do
    Logger.log(
      rpc.log_level,
      "GrpcX ERROR client='#{rpc.client_name}' rpc='#{rpc.method_name}' #{msg}"
    )
  end
end
