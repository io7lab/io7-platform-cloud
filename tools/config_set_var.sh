#!/usr/bin/bash
#
#   this sets the configuration variable 

if [ $# -lt 2 ]; then
    echo Usage
    echo $0 "<id> <value>"
    exit
fi

proto=${3:-http}

pw=${io7pw:-strong!!!}    # it uses the environment variable io7pw, so set it to your io7 password
token=$(curl -k -X POST "$proto://localhost:2009/users/login" -H 'Content-Type: application/json' \
    -d "{ \"email\": \"io7@io7lab.com\", \"password\": \"$pw\" }"|jq '.access_token'|tr -d '"') 2>/dev/null

curl -k -X 'PUT' \
    "$proto://localhost:2009/config/$1" \
    -H 'accept: application/json' \
    -H "Authorization: Bearer $token" \
    -H 'Content-Type: application/json' \
    -d "{
      \"value\": \"$2\"
    }"