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
  end

  test "it returns errors" do
    assert {:error, results} = __MODULE__.Example3.load_resources()

    assert results.user == {:error, :not_found}
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
