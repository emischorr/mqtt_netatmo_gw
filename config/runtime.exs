import Config

config :mqtt_netatmo_gw, :netatmo,
  client_id: System.get_env("NETATMO_CLIENT_ID") || raise("Missing env NETATMO_CLIENT_ID"),
  client_secret: System.get_env("NETATMO_CLIENT_SECRET") || raise("Missing env NETATMO_CLIENT_SECRET"),
  refresh_token: System.get_env("NETATMO_REFRESH_TOKEN") || raise("Missing env NETATMO_REFRESH_TOKEN")

config :mqtt_netatmo_gw, :mqtt,
  host: System.get_env("MQTT_HOST") || "127.0.0.1",
  port: System.get_env("MQTT_PORT") || 1883,
  username: System.get_env("MQTT_USER") || nil,
  password: System.get_env("MQTT_PW") || nil,
  event_topic_namespace: System.get_env("MQTT_EVENT_TOPIC_NS") || "home/get/netatmo_gw"
