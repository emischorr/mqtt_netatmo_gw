defmodule MqttNetatmoGw.WeatherStation do
  use GenServer
  require Logger

  alias MqttNetatmoGw.Netatmo
  alias MqttNetatmoGw.Mqtt

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

    {:ok, mqtt_client_id} = Mqtt.connect()
    Mqtt.publish_meta(mqtt_client_id)

    Process.send_after(self(), :update, 10_000)
    {:noreply, %{mqtt_client_id: mqtt_client_id, config: config}}
  end

  def handle_info(:update, state) do
    update(state.mqtt_client_id, Netatmo.token())
    Process.send_after(self(), :update, state.config[:update_interval])
    {:noreply, state}
  end

  def handle_info(unknown, state) do
    Logger.warning("Unknown call to handle info with: #{inspect(unknown)}")
    {:noreply, state}
  end

  def handle_call(:refresh, _from, state) do
    update(state.mqtt_client_id, Netatmo.token())
    {:reply, :ok, state}
  end

  defp update(mqtt_client_id, access_token) do
    Enum.each(weather_data(access_token), fn {module, data} ->
      Enum.each(data, fn {key, value} ->
        Mqtt.publish(mqtt_client_id, "#{module}/#{key}", value)
      end)
      Mqtt.publish(mqtt_client_id, "#{module}/last_update", now())
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

  defp build_module_data(%{"module_name" => name, "reachable" => false, "battery_percent" => battery}) do
    Logger.warning("Module #{name} not reachable. Battery level: #{battery}%")
    %{}
  end

  defp build_module_data(%{"module_name" => name, "dashboard_data" => data, "battery_percent" => battery}) do
    module_data = data
    |> filter_data()
    |> Map.merge(%{battery: battery})
    %{name => module_data}
  end

  defp build_module_data(%{"module_name" => name, "dashboard_data" => data}) do
    %{name => filter_data(data)}
  end

  defp build_module_data(%{"module_name" => name}) do
    Logger.warning("No dashboard data for module #{name}.")
    %{}
  end

  defp filter_data(data) do
    Map.filter(data, fn {key, _value} -> key in @exported_fields end)
  end

  defp now, do: DateTime.utc_now(:second) |> DateTime.to_iso8601()
end
