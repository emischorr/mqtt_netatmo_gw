defmodule MqttNetatmoGw.Netatmo do
  use GenServer
  require Logger

  @token_refresh_interval :timer.hours(2)
  @token_file "tokens.json"

  # Client

  def start_link(opts) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def token do
    GenServer.call(__MODULE__, :token)
  end


  # Server

  def init(_args) do
    config = Application.get_env(:mqtt_netatmo_gw, :netatmo)
    {access_token, refresh_token} = case read_tokens() do
      {at, rt} -> {at, rt}
      _else -> {nil, config[:refresh_token]}
    end
    Process.send_after(self(), :refresh_token, 1_000)
    {:ok, %{config: config, access_token: access_token, refresh_token: refresh_token}}
  end

  def handle_call(:token, _from, state) do
    {:reply, state.access_token, state}
  end

  def handle_info(:refresh_token, state) do
    Process.send_after(self(), :refresh_token, @token_refresh_interval)
    {:noreply, refresh_token(state)}
  end

  defp refresh_token(%{config: config} = state) do
    case Netatmox.refresh_token(config[:client_id], config[:client_secret], state.refresh_token) do
      {:ok, %{"refresh_token" => new_refresh_token, "access_token" => new_access_token}} ->
        Logger.info("Updated tokens. Access: #{new_access_token} / Refresh: #{new_refresh_token}")
        persist_tokens(new_access_token, new_refresh_token)

        state
        |> Map.replace(:refresh_token, new_refresh_token)
        |> Map.replace(:access_token, new_access_token)

      {:ok, %{"error" => error_msg}} ->
        Logger.warning("Refreshing token failed: #{inspect(error_msg)}")
        state
    end
  end

  defp persist_tokens(access_token, refresh_token) do
    case File.write(token_file_path(), '{"access_token": "#{access_token}", "refresh_token": "#{refresh_token}"}') do
      :ok -> Logger.info("Saved tokens to #{token_file_path()}")
      {:error, reason} -> Logger.warning("Could not persist tokens to '#{token_file_path()}': #{inspect(reason)}")
    end
  end

  defp read_tokens do
    with {:ok, json} <- File.read(token_file_path()),
      {:ok, %{access_token: at, refresh_token: rt}} <- Jason.decode(json, keys: :atoms!)
    do
      {at, rt}
    else
      {:error, %Jason.DecodeError{data: data}} -> Logger.warning("Could not decode tokens: #{inspect(data)}")
      {:error, reason} -> Logger.warning("Could not read tokens: #{inspect(reason)}")
    end
  end

  defp token_file_path, do: Application.app_dir(:mqtt_netatmo_gw, "priv") |> Path.join(@token_file)

end
