defmodule MqttNetatmoGwTest.Fixtures.Netatmox do
  def station_data() do
    [
      %{
        "_id" => "70:ee:50:11:22:33",
        "co2_calibrating" => false,
        "dashboard_data" => %{
          "AbsolutePressure" => 1013.6,
          "CO2" => 1043,
          "Humidity" => 66,
          "Noise" => 41,
          "Pressure" => 1037.1,
          "Temperature" => 21.8,
          "date_max_temp" => 1729699654,
          "date_min_temp" => 1729658465,
          "max_temp" => 21.9,
          "min_temp" => 20.8,
          "pressure_trend" => "down",
          "temp_trend" => "stable",
          "time_utc" => 1729709313
        },
        "data_type" => ["Temperature", "CO2", "Humidity", "Noise", "Pressure"],
        "date_setup" => 1491633265,
        "firmware" => 204,
        "home_id" => "5a04a3df29977e09123b123e",
        "home_name" => "MyHome",
        "last_setup" => 1491633265,
        "last_status_store" => 1729709314,
        "last_upgrade" => 1491633269,
        "module_name" => "Living Room",
        "modules" => [
          %{
            "_id" => "02:00:00:22:33:44",
            "battery_percent" => 67,
            "battery_vp" => 5404,
            "dashboard_data" => %{
              "Humidity" => 86,
              "Temperature" => 12.3,
              "date_max_temp" => 1729690232,
              "date_min_temp" => 1729669059,
              "max_temp" => 14.2,
              "min_temp" => 7.7,
              "temp_trend" => "stable",
              "time_utc" => 1729709304
            },
            "data_type" => ["Temperature", "Humidity"],
            "firmware" => 53,
            "last_message" => 1729709311,
            "last_seen" => 1729709304,
            "last_setup" => 1491633290,
            "module_name" => "Outdoor",
            "reachable" => true,
            "rf_status" => 72,
            "type" => "NAModule1"
          },
          %{
            "_id" => "03:00:00:00:00:00",
            "battery_percent" => 0,
            "battery_vp" => 4200,
            "data_type" => ["Temperature", "CO2", "Humidity"],
            "firmware" => 53,
            "last_message" => 1718232033,
            "last_seen" => 1718231988,
            "last_setup" => 1603179878,
            "module_name" => "Office",
            "reachable" => false,
            "rf_status" => 76,
            "type" => "NAModule4"
          }
        ],
        "place" => %{
          "altitude" => 193,
          "city" => "Springfield",
          "country" => "DE",
          "location" => [10.19, 48.35],
          "timezone" => "Europe/Berlin"
        },
        "reachable" => true,
        "station_name" => "MyHome (Living Room)",
        "type" => "NAMain",
        "wifi_status" => 60
      }
    ]
  end
end
