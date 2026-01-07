#!/bin/bash
#
# This script reverts the currently protected io7 platform back to non-secure mode
# all data are kept intact
function usage {
    echo "Description"
    echo "    This script adds, updates, or removes settings in a docker-compose.yml file."
    echo
    echo "Usage:"
    echo "    Run $(basename $0) with the container configuration specified in the following format:"
    echo "        \"[-] svc_config: key=value\""
    echo "    The entire argument must be enclosed in double quotes."
    echo "    Use '-' to remove a setting."
    echo
    echo "Example (add or modify a setting):"
    echo "    $(basename $0) \"services.nodered.environment: NODE_RED_ENABLE_PROJECTS=true\""
    echo
    echo "Where:"
    echo "    services.nodered.environment  → svc_config"
    echo "    NODE_RED_ENABLE_PROJECTS      → key"
    echo "    true                          → value"
    echo
    echo "Remove a setting:"
    echo "    Prefix the svc_config with '-'. The value can be omitted."
    echo
    echo "    $(basename $0) \"- services.nodered.environment: NODE_RED_ENABLE_PROJECTS\""
    echo
    echo "Argument Examples"
    echo "      - services.mqtt.ports: 1883:1883"
    echo "      services.mqtt.ports: 8883:8883"
    echo "      services.nodered.volumes: ./data/certs:/data/certs"
    echo "      services.influxdb.environment: INFLUXD_TLS_CERT=/data/certs/iothub.crt"
    echo "      services.influxdb.environment: INFLUXD_TLS_KEY=/data/certs/iothub.key"
    echo "      services.grafana.environment: GF_SERVER_ROOT_URL=https://iot201.ddns.net:3003"
}
if [ $# -le 0 ] ; then
    usage
    exit
fi

#if [[ ! "$1" =~ ^[[:space:]]*(-[[:space:]]*)?services\. ]]; then
#  echo "Error: argument must start with 'services.' or '- services.'"
#  exit 1
#fi

if [ -z $NODE_PATH ] ; then
    export NODE_PATH=$(dirname $(which node))/../lib/node_modules
fi
dir=$(pwd)/$(dirname $(echo $0))

node $dir/modify-docker-compose.js ~/docker-compose.yml <<EOF
$1
EOF

echo 
echo "The io7 Platform needs to be restarted to have the change applied"
echo "Run these commands at the home folder"
echo 
echo "cd ~"
echo "docker compose down"
echo "docker compose up -d"

