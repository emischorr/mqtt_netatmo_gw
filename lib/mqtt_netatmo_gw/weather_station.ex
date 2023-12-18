defmodule MqttNetatmoGw.WeatherStation do
  use GenServer
  require Logger

  alias MqttNetatmoGw.Mqtt

  @token_refresh_interval :timer.hours(1)
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

  def handle_call(:refresh, _from, state) do
    update(state)
    {:reply, :ok, state}
  end

  defp refresh_token(%{config: config} = state) do
    refresh_token = state.refresh_token || config[:refresh_token]

    {:ok, %{"refresh_token" => refresh_token, "access_token" => access_token}} =
      Netatmox.refresh_token(config[:client_id], config[:client_secret], refresh_token)

    Logger.info("Updated tokens. Access: #{access_token} / Refresh: #{refresh_token}")

    state
    |> Map.put(:refresh_token, refresh_token)
    |> Map.put(:access_token, access_token)
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
        main_device = Enum.filter(devices, &(&1["type"] == "NAMain")) |> List.first()
        Enum.map(main_device["modules"], fn module ->
          %{module["module_name"] => filter_data(module["dashboard_data"])}
        end)
        |> List.foldl(%{}, fn x, acc -> Map.merge(x, acc) end)
        |> Map.merge(%{main_device["module_name"] => filter_data(main_device["dashboard_data"])})
      unexpected_error ->
        Logger.warning("Could not get weather data: #{inspect unexpected_error}")
        %{}
    end
  end

  defp filter_data(data) do
    Map.filter(data, fn {key, _value} -> key in @exported_fields end)
  end
end
