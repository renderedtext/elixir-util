defmodule Util.GrpcX.Middlewares.ResponseStatusToErorr do
  def call(req, opts, next) do
    resp = next.(req, opts)

    case resp do
      {:ok, reply} ->
        if Map.has_key?(reply, :response_status) do
          status = Map.fetch!(reply, :response_status)

          if status.code == 0 do
            {:ok, reply}
          else
            {:error, reply}
          end
        else
          {:ok, reply}
        end

      any ->
        any
    end
  end
end
