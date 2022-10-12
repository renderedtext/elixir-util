defmodule Util.Loader do
  def load(tasks) do
    with :ok <- validate(tasks) do
      execute(tasks, %{})
    end
  end

  defp execute(tasks, results) do
    {runnable, rest} = Enum.split_with(tasks, fn t ->
      required_deps = deps(t)
      resolved_deps = MapSet.new(Map.keys(results))

      MapSet.subset?(required_deps, resolved_deps)
    end)

    new_results = Enum.map(runnable, fn t ->
      deps = extract_deps(t, results)

      Task.async(fn ->
        case fun(t).(deps, []) do
          {:ok, res} -> {name(t), res}
          e -> {:error, e}
        end
      end)
    end)
    |> Task.await_many()
    |> Enum.into(%{})

    results = Map.merge(results, new_results)

    if rest == [] do
      {:ok, results}
    else
      execute(rest, results)
    end
  end

  defp name(task) do
    elem(task, 0)
  end

  defp fun(task) do
    elem(task, 1)
  end

  defp deps(task) do
    case task do
      {name, fun} -> MapSet.new([])
      {name, fun, opts} -> MapSet.new(Keyword.get(opts, :depends_on, []))
    end
  end

  defp extract_deps(task, results) do
    deps(task) |> Enum.map(fn d ->
      {d, Map.get(results, d)}
    end) |> Enum.into(%{})
  end

  defp validate(tasks) do
    :ok
  end
end
