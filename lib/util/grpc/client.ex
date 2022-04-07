defmodule Util.Grpc.Client do
  defstruct :name, :endpoint, :timeout, :log_level, :publish_metrics, :stub

  @type t() :: {
    name: String.t(),
    endpoint: String.t(),
    timeout: number(),
    log_level: atom(),
    publish_metrics: boolean(),
    stub: Grpc.Stub.t()
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

  def call(client, method_name, request, opts \\ []) do
    metric_name = "grpc.#{client.name}.#{method_name}"

    result = Wormhole.capture(fn ->
      Watchman.benchmark("#{metric_name}.duration", fn ->
        Watchman.increment("#{metric_name}.connect.count")

        case Grpc.Stub.connect(client.endpoint) do
          {:ok, channel} ->
            res = GRPC.Stub.call(client.stub, method_name, channel, request, opts)

            case res do
              {:ok, res} ->
                Watchman.increment("#{metric_name}.response.success.count")
                {:ok, res}

              {:error, err} ->
                Watchman.increment("#{metric_name}.response.error.count")
                {:error, err}
            end

          {:error, error} ->
            Logger.log(client.level, "Failed to connect to #{client.name} service err='#{inspect(error)}'")
            Watchman.increment("#{metric_name}.connect.error.count")
        end
      end)
    end)

    case result do
      {:ok, result} ->
        result

      {:error, err} ->
        Logger.log(client.level, "Error while processing #{client.name} service err='#{inspect(error)}'")
        Watchman.increment("grpc.#{client.name}.execution.error")
    end
  end
end
