/*
 * Update this file to set the following variables if you want
 *     API_URL_ROOT
 *     WS_SERVER_URL
 *
 */
window["runtime"] = {
     "ws_protocol":"ws://",
     "mqtt_options" : {
        "username": "$web",
        "clean_session": true,
        "tls_insecure": false,
        "rejectUnauthorized": true
    }
}