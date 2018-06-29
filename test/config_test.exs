defmodule Util.ConfigTest do
  use ExUnit.Case

  alias Util.Config

  test "sys2app_env" do
    app = :foo
    value = "baz"
    System.put_env("BAR", value)
    assert Config.sys2app_env(app, "BAR", :bar) == app
    assert Application.get_env(app, :bar) == value
  end

  test "set_watchman_prefix - list of env vars" do
    app = :watchman
    observed_app = "ppl"
    value = "something"
    System.put_env("BAR", value)
    env_vars = ~w(UNDEFINED_ENV_VAR BAR)
    assert Config.set_watchman_prefix(env_vars, observed_app) == app
    assert Application.get_env(app, :prefix) == observed_app <> "." <> value
  end

  test "set_watchman_prefix" do
    app = :watchman
    observed_app = "ppl"
    value = "baz"
    System.put_env("BAR", value)
    assert Config.set_watchman_prefix("BAR", observed_app) == app
    assert Application.get_env(app, :prefix) == observed_app <> "." <> value
  end

  test "get_cooling_time" do
    assert Config.get_cooling_time(:util, :does_not_exist) == 123
    assert Config.get_cooling_time(:util, :test_val) == 456
  end
end
