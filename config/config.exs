import Config

config :logger,
  backends: [:console]

config :logger, :console,
  level: :info

config :tesla, adapter: {Tesla.Adapter.Mint, timeout: 5_000}

config :mqtt_netatmo_gw, :weather_station,
  update_interval: 5*60*1000

import_config "#{config_env()}.exs"
