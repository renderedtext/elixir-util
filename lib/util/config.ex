defmodule Util.Config do
  @moduledoc """
  Runtime configuration
  """

  @doc """
  Update application environment from system environment
  """
  def sys2app_env(app, sys_env_var, app_env_var)
  when is_binary(sys_env_var) and is_atom(app) and is_atom(app_env_var) do
    value = System.get_env(sys_env_var)
    Application.put_env(app, app_env_var, value)
    app
  end

  @doc """
  Use first non-nil environment variable value from "sys_env_vars" list
  of environment variables as application environment value for StatsD.
  """
  def set_watchman_prefix(sys_env_vars, app) when is_list(sys_env_vars) do
    sys_env_vars
    |> Enum.find_value(fn name -> System.get_env(name) end)
    |> set_watchman_prefix_(app)
  end

  @doc """
  Set application environment to "sys_env_var" env var value.
  """
  def set_watchman_prefix(sys_env_var, app) when is_binary(sys_env_var), do:
    sys_env_var |> System.get_env() |> set_watchman_prefix_(app)

  defp set_watchman_prefix_(_app_env = nil, _app), do: nil
  defp set_watchman_prefix_(app_env, app), do:
     put_env(:watchman, :prefix, "#{app}.#{app_env}")

  defp put_env(_app, _key, _value = nil), do: nil
  defp put_env(app, key, value) do
    Application.put_env(app, key, value, persistent: true)
    app
  end

  @doc """
  Helper function for setting either general or specific looper cooling time if it's set
  """
  def get_cooling_time(app, specific_value_name) do
    Application.get_env(app, specific_value_name)
    || Application.get_env(app, :general_looper_cooling_time_sec)
  end

  @doc """
  Helper function for setting either general or specific looper sleeping period if it's set
  """
  def get_sleeping_period(app, specific_value_name) do
    Application.get_env(app, specific_value_name)
    || Application.get_env(app, :general_sleeping_period_ms)
  end
end
