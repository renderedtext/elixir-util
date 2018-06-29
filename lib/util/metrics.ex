defmodule Util.Metrics do
  @moduledoc """
  """

  @doc """
  Send metric while executing function:
  - increment count (of type counter) by 1 when entering the function
  - increment count (of type timer) by 1 when exiting the function
  - function latency
  """
  def benchmark(metric_name, tag, f)
      when is_binary(metric_name) and (is_binary(tag) or is_atom(tag)) and is_function(f, 0),
    do: benchmark(metric_name, [tag], f)

  def benchmark(metric_name, tags, f)
      when is_binary(metric_name) and is_list(tags) and is_function(f, 0) do
    dashed_tags = tags |> Enum.map(&dot2dash(&1))
    {metric_name, dashed_tags} |> benchmark(f)
  end

  def benchmark(metric_name, f)
      when (is_binary(metric_name) or is_tuple(metric_name)) and is_function(f, 0) do
    Watchman.benchmark(metric_name, fn ->
      Watchman.increment(metric_name)

      f.()
    end)
  end

  @doc """
  This function:
  - Removes 'Elixir.' prefix from elixir atoms
  - replaces dots with dashes - this is essencial for metric tags
  """
  def dot2dash(tag) when is_atom(tag), do:
    tag |> Atom.to_string() |> String.replace_prefix("Elixir.", "") |> dot2dash()
  def dot2dash(tag) when is_binary(tag), do: tag |> String.replace(".", "-")
end
