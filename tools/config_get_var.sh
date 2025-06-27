#!/usr/bin/env bash
# adding io7 Devices
if [ $# -lt 1 ]; then
    echo Usage
    echo $0 "<id>"
    exit
fi
proto=${2:-http}

pw=${io7pw:-strong!!!}    # it uses the environment variable io7pw, so set it to your io7 password
echo $pw
token=$(curl -k -X POST "$proto://localhost:2009/users/login" -H 'Content-Type: application/json' -d "{ \"email\": \"io7@io7lab.com\", \"password\": \"$pw\" }"|jq '.access_token'|tr -d '"') 2>/dev/null

if [ $# -ge 1 ]; then
  curl -k -X 'GET' \
    "$proto://localhost:2009/config/$1" \
    -H 'accept: application/json' \
    -H "Authorization: Bearer $token" |jq
fi
