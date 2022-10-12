defmodule Util.LoaderTest do
  use ExUnit.Case, async: true

  alias Util.Loader

  test "it can laod things in parallel" do
    assert {:ok, results} = __MODULE__.Example1.load_resources()

    assert results.user == "Mike"
    assert results.org == "Acme"
  end

  test "it can wait on dependencies" do
    assert {:ok, results} = __MODULE__.Example2.load_resources()

    assert results.user == "Mike"
    assert results.permissions == "Mike is an admin"

    resources = [
      {:a, fn _, _ -> {:ok, "a"} end},
      {:b, fn _, _ -> {:ok, "b"} end, depends_on: [:a]},
      {:c, fn _, _ -> {:ok, "c"} end, depends_on: [:b]},
    ]

    assert {:ok, %{a: "a", b: "b", c: "c"}} = Loader.load(resources)
  end

  test "it can return errors" do
    assert {:error, results} = __MODULE__.Example3.load_resources()

    assert results.user == {:error, :not_found}
  end

  test "it returns an error if an unknown dependency is required" do
    resources = [
      {:a, fn _, _ -> {:ok, nil} end},
      {:b, fn _, _ -> {:ok, nil} end, depends_on: [:c]},
    ]

    assert {:error, :unprocessed, [:b]} = Loader.load(resources)
  end

  test "it returns an error if there is a cycle in the deps" do
    resources = [
      {:a, fn _, _ -> {:ok, nil} end},
      {:b, fn _, _ -> {:ok, nil} end, depends_on: [:c]},
      {:c, fn _, _ -> {:ok, nil} end, depends_on: [:b]},
    ]

    assert {:error, :unprocessed, [:b, :c]} = Loader.load(resources)

    resources = [
      {:a, fn _, _ -> {:ok, nil} end},
      {:b, fn _, _ -> {:ok, nil} end, depends_on: [:d]},
      {:c, fn _, _ -> {:ok, nil} end, depends_on: [:b]},
      {:d, fn _, _ -> {:ok, nil} end, depends_on: [:c]},
    ]

    assert {:error, :unprocessed, [:b, :c, :d]} = Loader.load(resources)
  end

  defmodule Example1 do
    def load_resources do
      Loader.load([
        {:user, &load_user/2},
        {:org, &load_org/2}
      ])
    end

    defp load_user(_deps, _args), do: {:ok, "Mike"}
    defp load_org(_deps, _args), do: {:ok, "Acme"}
  end

  defmodule Example2 do
    def load_resources do
      Loader.load([
        {:user, &load_user/2},
        {:permissions, &load_permissions/2, depends_on: [:user]}
      ])
    end

    defp load_user(_deps, _args), do: {:ok, "Mike"}
    defp load_permissions(%{user: user}, _args), do: {:ok, "#{user} is an admin"}
  end

  defmodule Example3 do
    def load_resources do
      Loader.load([
        {:user, &load_user/2},
        {:org, &load_org/2}
      ])
    end

    defp load_user(_deps, _args), do: {:error, :not_found}
    defp load_org(_deps, _args), do: {:ok, "Acme"}
  end
end
