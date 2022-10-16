defmodule Util.Loader do
  alias __MODULE__.LoadTask
  alias __MODULE__.Results

  def load(definitions) do
    tasks = Enum.map(definitions, &LoadTask.new/1)

    with(
      :ok <- check_unknown_deps(tasks),
      :ok <- check_deps_cycle(tasks)
    ) do
      execute(tasks, Results.new())
    end
  end

  defp execute(tasks, results) do
    {runnable, rest} = find_runnable(tasks, already_executed: Results.executed_task_ids(results))

    if runnable == [] && rest != [] do
      {:error, :unprocessed, Enum.map(rest, fn r -> r.id end)}
    else
      new_results =
        runnable
        |> Enum.map(fn t -> LoadTask.execute_async(t, Results.fetch(results, t.deps)) end)
        |> Task.await_many()
        |> Enum.into(%{})

      case process(new_results) do
        {:ok, new_results} ->
          results = Map.merge(results, new_results)

          if rest == [] do
            {:ok, results}
          else
            execute(rest, results)
          end

        {:error, new_results} ->
          results = Map.merge(results, new_results)

          {:error, results}
      end
    end
  end

  defp process(raw_results) do
    res = Enum.reduce(raw_results, {:ok, []}, fn r, {type, acc} ->
      case r do
        {name, {:ok, val}} -> {type, acc ++ [{name, val}]}
        {name, e} -> {:error, acc ++ [{name, e}]}
      end
    end)

    {elem(res, 0), Enum.into(elem(res, 1), %{})}
  end

  defp check_deps_cycle(tasks, visited \\ []) do
    {visitable, rest} = find_runnable(tasks, already_executed: visited)

    cond do
      visitable == [] && rest == [] ->
        :ok

      visitable == [] && rest != [] ->
        {:error, :dependency_cycle}

      true ->
        check_deps_cycle(rest, visited ++ Enum.map(visitable, &(&1.id)))
    end
  end

  defp check_unknown_deps(tasks) do
    names = Enum.map(tasks, &(&1.id))

    tasks
    |> Enum.map(fn task ->
      unknown_deps = Enum.filter(task.deps, fn d -> d not in names end)

      {task.id, unknown_deps}
    end)
    |> Enum.filter(fn {id, unknown_deps} ->
      unknown_deps != []
    end)
    |> case do
      [] -> :ok
      e -> {:error, :unknown_dependency, Enum.into(e, %{})}
    end
  end

  defp subset?(arr1, arr2) do
    MapSet.subset?(MapSet.new(arr1), MapSet.new(arr2))
  end

  defp find_runnable(tasks, already_executed: ids) do
    Enum.split_with(tasks, fn t -> subset?(t.deps, ids) end)
  end

  defmodule LoadTask do
    def new({id, fun}) do
      new({id, fun, []})
    end

    def new({id, fun, opts}) do
      %{
        id: id,
        fun: fun,
        deps: Keyword.get(opts, :depends_on, [])
      }
    end

    def execute_async(task, deps) do
      Task.async(fn ->
        execute(task, deps)
      end)
    end

    defp execute(task, deps) do
      Wormhole.capture(fn -> dispatch_call(task.fun, deps) end)
      |> case do
        {:ok, res} -> {task.id, res}
        e -> {task.id, e}
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

  defmodule Results do
    def new(), do: %{}
    def executed_task_ids(r), do: Map.keys(r)

    def fetch(r, ids) do
      Enum.filter(r, fn {k, v} -> k in ids end) |> Enum.into(%{})
    end
  end

end
