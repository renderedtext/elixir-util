defmodule Util.Loader do
  def load(tasks) do
    execute(tasks, %{})
  end

  defp execute(tasks, results) do
    {runnable, rest} = Enum.split_with(tasks, fn t ->
      required_deps = deps(t)
      resolved_deps = MapSet.new(Map.keys(results))

      MapSet.subset?(required_deps, resolved_deps)
    end)

    if runnable == [] && rest != [] do
      {:error, :unprocessed, Enum.map(rest, fn r -> name(r) end)}
    else
      new_results = Enum.map(runnable, fn t ->
        deps = extract_deps(t, results)

        Task.async(fn ->
          {name(t), fun(t).(deps, [])}
        end)
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
end
