#!/bin/bash
#   This script setup the default Grafana Dashboard and the required objects such as
#       the service account & token, and an influxdb datasource.
#   This needs io7 admin user's password and influxdb access token
#   If those things need to be configured again, then remove
#       dashboard if exists
#       datasource if exists
#       service accounts if exists
#

api_user_email=$1
api_user_pw=$2
influxdb_token=$3

insecure=''
proto='http'
if [ -f ~/data/certs/iothub.crt ]; then
  insecure='--insecure'
  proto='https'
fi

function add_config_var {
    curl $insecure -X 'PUT' "http://localhost:2009/config/$1" \
        -H 'accept: application/json' -H "Authorization: Bearer $api_token" \
        -H 'Content-Type: application/json' \
        -d "{ \"value\": \"$2\" }"
}

api_token=$(curl -X POST 'http://localhost:2009/users/login' \
    -H 'Content-Type: application/json' \
    -d "{ \"email\": \"$api_user_email\", \"password\": \"$api_user_pw\" }" \
    |jq '.access_token'|tr -d '"') 2>/dev/null

echo 'creating service account'
gf_auth_header="Authorization: Basic $(echo -n "admin:$api_user_pw" | base64)"
response=$(curl -X POST -H "Content-Type: application/json"                     \
    -H "$gf_auth_header" -d '{"name": "io7-service-account", "role": "Admin"}'  \
    http://localhost:3003/api/serviceaccounts 2>/dev/null)
gf_svcid=$(echo $response|jq '.id')

if [ "$gf_svcid" = "null" ]; then
    echo "There is an issue in the service token creation"
    err_msg=$(echo $response|jq '.message')
    if [ "$err_msg" != "null" ] ; then
        echo $response
    fi
    exit 1
fi

echo 'creating service token'
gf_token=$(curl -X POST -H "Content-Type: application/json"     \
    -H "$gf_auth_header" -d '{"name": "io7-service-token"}'     \
    "http://localhost:3003/api/serviceaccounts/$gf_svcid/tokens" 2>/dev/null |jq '.key'|tr -d \")

# adding influx datasource to grafana
echo 'adding influx datasource for grafana'
datasource_uid=$(curl -X POST http://localhost:3003/api/datasources \
-H "Authorization: Bearer $gf_token" \
-H "Content-Type: application/json" \
-d "{
    \"name\":\"io7db\",
    \"type\":\"influxdb\",
    \"url\":\"http://influxdb:8086\",
    \"access\":\"proxy\",
    \"jsonData\":{
        \"version\":\"Flux\",
        \"organization\":\"io7org\",
        \"defaultBucket\":\"bucket01\"
    },
    \"secureJsonData\": {
        \"token\":\"$influxdb_token\"
    }
}" 2>/dev/null | jq '.datasource.uid')

echo 'adding grafana dashboard'
# adding grafana dashboard
dashboard_json='{
  "dashboard": {
    "title": "Dashboard 1",
    "timezone": "browser",
    "editable": true,
    "version": 2,
    "panels": [
      {
        "gridPos": { "h": 8, "w": 24, "x": 0, "y": 0 },
        "id": 1,
        "options": {
          "legend": {
            "calcs": [],
            "displayMode": "list",
            "placement": "bottom",
            "showLegend": true
          },
          "tooltip": {
            "hideZeros": false,
            "mode": "single",
            "sort": "none"
          }
        },
        "pluginVersion": "12.0.1",
        "targets": [
          {
            "datasource": {
              "type": "influxdb",
              "uid": DATASOURCE_UID
            },
            "query": "from(bucket: \"bucket01\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"alldevices\")\n  |> yield(name: \"point\")",
            "refId": "A"
          }
        ],
        "title": "IOT Data",
        "type": "timeseries"
      }
    ],
    "time": {
      "from": "now-15m",
      "to": "now"
    }
  },
  "overwrite": true
}'
dashboard_json=${dashboard_json//DATASOURCE_UID/$datasource_uid}

dashboard_uid=$(curl -s -X POST "http://localhost:3003/api/dashboards/db" \
  -H "Authorization: Bearer $gf_token" \
  -H "Content-Type: application/json" \
  -d "$dashboard_json" 2>/dev/null | jq '.uid'|tr -d \")

# adding configuration parameters
add_config_var influxdb_token "$influxdb_token"
add_config_var gf_token "$gf_token"
add_config_var monitored_devices "*"
add_config_var monitored_fieldsets "temperature, humidity, lux, brightness"
echo Making the default dashboard public
# making the default dashboard public
accessToken=$(curl -X POST \
  "http://localhost:3003/api/dashboards/uid/$dashboard_uid/public-dashboards/" \
  -H "Authorization: Bearer $gf_token" \
  -H "Content-Type: application/json" \
  -d '{
    "isEnabled": true,
    "share": "public"
  }' 2>/dev/null | tee | jq '.accessToken'|tr -d \")
add_config_var dashboard "http://localhost:3003/public-dashboards/$accessToken"

echo the public dashboard is configured
exit 0