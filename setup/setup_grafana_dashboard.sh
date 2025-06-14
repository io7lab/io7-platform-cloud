#!/bin/bash
#   This script setup the default Grafana Dashboard and the required objects such as
#       the service account & token, and an influxdb datasource.
#   This needs io7 admin user's password and influxdb access token
#   If those things need to be configured again, then remove
#       dashboard if exists
#       datasource if exists
#       service accounts if exists
#

api_user_pw=$1
influx_token=$2

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
curl -X POST http://localhost:3003/api/datasources \
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
        \"token\":\"$influx_token\"
    }
}" 2>/dev/null

# adding grafana dashboard
echo 'adding grafana dashboard'

dashboard_json='{
  "dashboard": {
    "title": "Dashboard 1",
    "panels": [
      {
        "title": "IOT Data",
        "type": "timeseries",
        "targets": [
          {
            "datasource": {
              "type": "influxdb"
            },
            "query": "from(bucket: \"bucket01\")\n  |> range(start: v.timeRangeStart, stop: v.timeRangeStop)\n  |> filter(fn: (r) => r[\"_measurement\"] == \"alldevices\")\n  |> yield(name: \"point\")",
            "refId": "A",
            "legendFormat": "{{_field}}({{device}})"
          }
        ],
        "gridPos": {"h": 8, "w": 24, "x": 0, "y": 0}
      }
    ],
    "time": {
      "from": "now-1h",
      "to": "now"
    },
    "refresh": "5s"
  },
  "overwrite": true
}'

curl -s -X POST "http://localhost:3003/api/dashboards/db" \
  -H "Authorization: Bearer $gf_token" \
  -H "Content-Type: application/json" \
  -d "$dashboard_json"

exit 0
