defmodule Util.LoaderTest do
  use ExUnit.Case, async: true

  alias Util.Loader

  test "it can laod things in parallel" do
    assert {:ok, results} = __MODULE__.Example1.load_resources()

    assert results.user == "Mike"
    assert results.org == "Acme"
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
end
