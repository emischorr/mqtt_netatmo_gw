defmodule MqttNetatmoGw.WeatherStation do
  use GenServer
  require Logger

  alias MqttNetatmoGw.Mqtt

  @token_refresh_interval :timer.hours(2)
  @exported_fields ["CO2", "Temperature", "Humidity", "Noise"]

  # Client

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def refresh do
    GenServer.call(__MODULE__, :refresh)
  end


  # Server

  def init(_args) do
    {:ok, nil, {:continue, :init}}
  end

  def handle_continue(:init, _state) do
    config = Application.get_env(:mqtt_netatmo_gw, :weather_station)
    |> Keyword.merge(Application.get_env(:mqtt_netatmo_gw, :netatmo))

    {:ok, mqtt_client_id} = Mqtt.connect()
    Mqtt.publish_meta(mqtt_client_id)

    Process.send_after(self(), :update, 10_000)
    Process.send_after(self(), :refresh_token, 1_000)
    {:noreply, %{mqtt_client_id: mqtt_client_id, config: config, access_token: nil, refresh_token: nil}}
  end

  def handle_info(:update, state) do
    update(state)
    Process.send_after(self(), :update, state.config[:update_interval])
    {:noreply, state}
  end

  def handle_info(:refresh_token, state) do
    Process.send_after(self(), :refresh_token, @token_refresh_interval)
    {:noreply, refresh_token(state)}
  end

  def handle_info(unknown, state) do
    Logger.warning("Unknown call to handle info with: #{inspect(unknown)}")
    {:noreply, state}
  end

  def handle_call(:refresh, _from, state) do
    update(state)
    {:reply, :ok, state}
  end

  defp refresh_token(%{config: config} = state) do
    current_refresh_token = state.refresh_token || config[:refresh_token]

    case Netatmox.refresh_token(config[:client_id], config[:client_secret], current_refresh_token) do
      {:ok, %{"refresh_token" => new_refresh_token, "access_token" => new_access_token}} ->
        Logger.info("Updated tokens. Access: #{new_access_token} / Refresh: #{new_refresh_token}")

        state
        |> Map.replace(:refresh_token, new_refresh_token)
        |> Map.replace(:access_token, new_access_token)

      {:ok, %{"error" => error_msg}} ->
        Logger.warning("Refreshing token failed: #{inspect(error_msg)}")
        state
    end
  end

  defp update(%{mqtt_client_id: mqtt_client_id, access_token: access_token}) do
    Enum.each(weather_data(access_token), fn {module, data} ->
      Enum.each(data, fn {key, value} ->
        Mqtt.publish(mqtt_client_id, "#{module}/#{key}", value)
      end)
    end)
  end

  defp weather_data(access_token) do
    case Netatmox.station_data(access_token) do
      {:ok, %{"body" => %{"devices" => devices}}} ->
        devices
        |> Enum.filter(&(&1["type"] == "NAMain"))
        |> List.first()
        |> extract_data()
      unexpected_error ->
        Logger.warning("Could not get weather data: #{inspect unexpected_error}")
        %{}
    end
  end

  defp extract_data(nil) do
    Logger.warning("No main device in response")
    %{}
  end

  defp extract_data(main_device) do
    Enum.map(main_device["modules"], &(build_module_data(&1)))
    |> List.foldl(%{}, fn x, acc -> Map.merge(x, acc) end)
    |> Map.merge(build_module_data(main_device))
  end

  defp build_module_data(%{"module_name" => name, "dashboard_data" => data}) do
    %{name => filter_data(data)}
  end

  defp build_module_data(%{"module_name" => name, "reachable" => false, "battery_percent" => battery}) do
    Logger.warning("Module #{name} not reachable. Battery level: #{battery}%")
    %{}
  end

  defp build_module_data(%{"module_name" => name}) do
    Logger.warning("No dashboard data for module #{name}.")
    %{}
  end

  defp filter_data(data) do
    Map.filter(data, fn {key, _value} -> key in @exported_fields end)
  end
end
