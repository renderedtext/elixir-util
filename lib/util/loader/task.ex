defmodule Util.Loader.Task do
  @moduledoc """
  An individual loading task.
  """

  defstruct [
    :id,
    :fun,
    :deps,
    :timeout
  ]

  def new(id, fun, opts) do
    timeout = Keyword.get(opts, :timeout, :infinity)
    deps = Keyword.get(opts, :depends_on, [])

    {:ok, struct(__MODULE__,
      id: id,
      fun: fun,
      deps: deps,
      timeout: timeout
    )}
  end

  def execute(task, deps) do
    Wormhole.capture(fn -> dispatch_call(task.fun, deps) end, [timeout: task.timeout])
    |> case do
      {:ok, {:ok, res}} -> {:ok, res}
      {:ok, {:error, err}} -> {:error, err}
      {:ok, other} -> {:error, :unexpected_result_type, other}
      {:error, err} -> {:error, err}
    end
  end

  defp dispatch_call(fun, deps) do
    case :erlang.fun_info(fun)[:arity] do
      0 -> fun.()
      1 -> fun.(deps)
      2 -> fun.(deps, [])
    end
  end
end
