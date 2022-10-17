defmodule Util.LoaderTest do
  use ExUnit.Case, async: true

  alias Util.Loader

  test "empty loaders return :ok" do
    assert {:ok, %{}} = Loader.load([])
  end

  test "it can laod things in parallel" do
    assert {:ok, resources} = Loader.load([
      {:user, fn -> {:ok, "Mike"} end},
      {:org, fn -> {:ok, "Acme"} end}
    ])

    assert resources.user == "Mike"
    assert resources.org == "Acme"
  end

  test "it can wait on dependencies" do
    assert {:ok, resources} = Loader.load([
      {:user, fn -> {:ok, "Mike"} end},
      {:permissions, fn deps -> {:ok, "#{deps.user} is an admin"} end, depends_on: [:user]}
    ])

    assert resources.user == "Mike"
    assert resources.permissions == "Mike is an admin"
  end

  test "multiple tasks with dependencies" do
    assert {:ok, resources} = Loader.load([
      {:a, fn -> {:ok, "a"} end},
      {:b, fn deps -> {:ok, deps.a <> "b"} end, depends_on: [:a]},
      {:c, fn deps -> {:ok, deps.b <> "c"} end, depends_on: [:b]},
    ])

    assert resources.a == "a"
    assert resources.b == "ab"
    assert resources.c == "abc"
  end

  test "it can return errors" do
    assert {:error, resources} = Loader.load([
      {:user, fn -> {:ok, "Mike"} end},
      {:org, fn -> {:error, :not_found} end}
    ])

    assert resources.org == {:error, :not_found}
  end

  test "it returns an error if an unknown dependency is required" do
    resources = [
      {:a, fn -> {:ok, nil} end},
      {:b, fn -> {:ok, nil} end, depends_on: [:c]},
    ]

    assert {:error, :unknown_dependency, %{b: [:c]}} = Loader.load(resources)
  end

  test "it returns an error if there is a cycle in the deps" do
    resources = [
      {:a, fn -> {:ok, nil} end},
      {:b, fn -> {:ok, nil} end, depends_on: [:c]},
      {:c, fn -> {:ok, nil} end, depends_on: [:b]},
    ]

    assert {:error, :dependency_cycle} = Loader.load(resources)

    resources = [
      {:a, fn -> {:ok, nil} end},
      {:b, fn -> {:ok, nil} end, depends_on: [:d]},
      {:c, fn -> {:ok, nil} end, depends_on: [:b]},
      {:d, fn -> {:ok, nil} end, depends_on: [:c]},
    ]

    assert {:error, :dependency_cycle} = Loader.load(resources)
  end

  test "it handles raised exceptions" do
    assert {:error, resources} = Loader.load([
      {:a, fn -> raise "failure" end},
      {:b, fn -> {:ok, nil} end, depends_on: [:a]},
    ])

    assert resources.a == {:error, {:shutdown, %RuntimeError{message: "failure"}}}
  end

  test "it respects the timeout" do
    assert {:error, {:timeout, 100}} = Loader.load([
      {:a, fn -> :timer.sleep(300) end},
      {:b, fn -> {:ok, nil} end, depends_on: [:a]},
    ], whole_operation_timeout: 100)
  end

  test "it respects per task timeout" do
    assert {:error, resources} = Loader.load([
      {:a, fn -> :timer.sleep(300) end, timeout: 100},
      {:b, fn -> {:ok, nil} end, depends_on: [:a]},
    ])

    assert resources.a == {:error, {:timeout, 100}}
  end

  test "it respects per task timeout defined on global level" do
    assert {:error, resources} = Loader.load([
      {:a, fn -> :timer.sleep(300) end},
      {:b, fn -> {:ok, nil} end, depends_on: [:a]},
    ], per_resource_timeout: 100)

    assert resources.a == {:error, {:timeout, 100}}
  end
end
