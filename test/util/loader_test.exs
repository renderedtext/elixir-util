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
      {:a, fn _, _ -> {:ok, nil} end},
      {:b, fn _, _ -> {:ok, nil} end, depends_on: [:c]},
    ]

    assert {:error, :unknown_dependency, %{b: [:c]}} = Loader.load(resources)
  end

  test "it returns an error if there is a cycle in the deps" do
    resources = [
      {:a, fn _, _ -> {:ok, nil} end},
      {:b, fn _, _ -> {:ok, nil} end, depends_on: [:c]},
      {:c, fn _, _ -> {:ok, nil} end, depends_on: [:b]},
    ]

    assert {:error, :dependency_cycle} = Loader.load(resources)

    resources = [
      {:a, fn _, _ -> {:ok, nil} end},
      {:b, fn _, _ -> {:ok, nil} end, depends_on: [:d]},
      {:c, fn _, _ -> {:ok, nil} end, depends_on: [:b]},
      {:d, fn _, _ -> {:ok, nil} end, depends_on: [:c]},
    ]

    assert {:error, :dependency_cycle} = Loader.load(resources)
  end
end
