defmodule Util.Loader.TaskTest do
  use ExUnit.Case, async: true

  test "construction" do
    assert {:ok, _} = Util.Loader.Task.new(:a, fn -> {:ok, "A"} end, depends_on: [:b, :d])
  end

  describe "execution" do
    test "ok result" do
      assert {:ok, task} = Util.Loader.Task.new(:a, fn -> {:ok, "A"} end, [])
      assert {:ok, "A"} = Util.Loader.Task.execute(task, %{})
    end

    test "error result" do
      assert {:ok, task} = Util.Loader.Task.new(:a, fn -> {:error, "B"} end, [])
      assert {:error, "B"} = Util.Loader.Task.execute(task, %{})
    end

    test "exception result" do
      fun = fn -> raise "AAA" end

      assert {:ok, task} = Util.Loader.Task.new(:a, fun, [])
      assert {:error, {:shutdown, %RuntimeError{message: "AAA"}}} = Util.Loader.Task.execute(task, %{})
    end

    test "non-tuple result" do
      assert {:ok, task} = Util.Loader.Task.new(:a, fn -> "A" end, [])
      assert {:error, :unexpected_result_type, "A"} = Util.Loader.Task.execute(task, %{})
    end

    test "timeout result" do
      fun = fn ->
        :timer.sleep(1000)
        {:ok, "A"}
      end

      assert {:ok, task} = Util.Loader.Task.new(:a, fun, timeout: 100)
      assert {:error, {:timeout, 100}} = Util.Loader.Task.execute(task, [])
    end

    test "with deps" do
      deps = %{a: "A", b: "B"}

      fun = fn deps ->
        {:ok, deps.a <> deps.b}
      end

      assert {:ok, task} = Util.Loader.Task.new(:a, fun, timeout: 100)
      assert {:ok, "AB"} = Util.Loader.Task.execute(task, deps)
    end
  end
end
