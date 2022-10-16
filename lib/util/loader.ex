defmodule Util.Loader do
  alias __MODULE__.LoadTask

  def load(definitions) do
    tasks = Enum.map(definitions, &LoadTask.new/1)

    with(
      :ok <- check_deps_cycle(tasks),
      :ok <- check_unknown_deps(tasks)
    ) do
      execute(tasks, %{})
    end
  end

  defp execute(tasks, results) do
    {runnable, rest} = Enum.split_with(tasks, fn t ->
      MapSet.subset?(MapSet.new(t.deps), MapSet.new(Map.keys(results)))
    end)

    if runnable == [] && rest != [] do
      {:error, :unprocessed, Enum.map(rest, fn r -> r.id end)}
    else
      new_results = Enum.map(runnable, fn t ->
        deps = extract_deps(t, results)

        LoadTask.execute_async(t, deps)
      end)
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

  defp name(task) do
    elem(task, 0)
  end

  defp extract_deps(task, results) do
    task.deps |> Enum.map(fn d ->
      {d, Map.get(results, d)}
    end) |> Enum.into(%{})
  end

  defp check_deps_cycle(tasks) do
    :ok
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

    def execute(task, deps) do
      case :erlang.fun_info(task.fun)[:arity] do
        0 -> task.fun.()
        1 -> task.fun.(deps)
        2 -> task.fun.(deps, [])
      end
    end

    def execute_async(task, deps) do
      Task.async(fn ->
        res = execute(task, deps)

        {task.id, res}
      end)
    end
  end
end
