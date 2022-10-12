defmodule Util.Loader do
  def load(tasks) do
    with :ok <- validate(tasks) do
      {:ok, Enum.map(tasks, fn {name, fun} ->
        Task.async(fn ->
          case fun.([], []) do
            {:ok, res} -> {name, res}
            e -> {:error, e}
          end
        end)
      end)
      |> Task.await_many()
      |> Enum.into(%{})}
    end
  end

  defp validate(tasks) do
    :ok
  end
end
