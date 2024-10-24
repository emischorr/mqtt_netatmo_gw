# MqttNetatmoGw

A MQTT gateway that brings weather station data from a netatmo account over to MQTT.
It connects and updates weather information ("CO2", "Temperature", "Humidity", "Noise") every 5 minutes. Supports multiple sensors/devices.

## ENV vars

Required:
`NETATMO_CLIENT_ID`
`NETATMO_CLIENT_SECRET`
`NETATMO_REFRESH_TOKEN`

Optional:
`MQTT_HOST` default "127.0.0.1"
`MQTT_PORT` default 1883
`MQTT_USER`
`MQTT_PW`
`MQTT_EVENT_TOPIC_NS` default "home/get/netatmo_gw"

## Installation / Running

docker run \
  -d \
  --name='MQTTNetatmoGW' \
  --net='bridge' \
  -e TZ="Europe/Berlin" \
  -e 'MQTT_HOST'='<192.168.0.100>' \
  -e 'MQTT_USER'='<a_user>' \
  -e 'MQTT_PW'='<a_password>' \
  -e 'NETATMO_CLIENT_ID'='<client_id>' \
  -e 'NETATMO_CLIENT_SECRET'='<client_secret>' \
  -e 'NETATMO_REFRESH_TOKEN'='<initial_refresh_token>' \
  -v '</some/path/on/your/host>':'/home/elixir/app/lib/mqtt_netatmo_gw-0.1.0/priv':'rw' 'emischorr/mqtt_netatmo_gw:latest'


You need to have a app created at the Netatmo Developer Portal: https://dev.netatmo.com/apps/
There you can find the needed client id and client secret.
Then also on the same page generate a token pair (with at least `read_station` scope) for your application and copy the refresh token.

All three (id, secret and refresh token) have to be supplied at the start via ENV vars.

If you don't supply any ENV vars for the MQTT connection it tries to connect to a instance running on localhost on the default port without access control.

Authentication with Netatmo is automatically renewed.
NOTICE: the tokens will be stored to disk in clear text.