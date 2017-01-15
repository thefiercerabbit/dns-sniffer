#!/bin/bash

function _exit_function() {
    kill -9 0
}

trap "_exit_function" 0

INTERFACE="wlan0"
OUT_FILE="/home/pi/dns.db"
OPTIONS="w:i:"

SSID="your_router_SSID"
PASSWORD="your_router_password"
CHANNEL="your_network_channel" 

while getopts $OPTIONS opt; do
    case $opt in
	'w' ) OUT_FILE="$OPTARG" ;;
	'i' ) INTERFACE="$OPTARG";;
	* ) exit;;
    esac
done

CAPTURE_PROGR='dumpcap'
CAPTURE_FLAGS="-q -i $INTERFACE -I -f '(link[0] != 0x80)' -w -"
FILTER_PROGR='tshark'
FILTER_FLAGS="-l -o wlan.enable_decryption:TRUE -o 'uat:80211_keys:\"wpa-pwd\",\"${PASSWORD}:${SSID}\"' -r - -Y '(dns)' -Tfields -E separator='|' -e frame.time_epoch -e wlan.ta -e wlan.ra -e ip.src -e ip.dst -e _ws.col.Protocol -e dns.qry.name -e dns.flags.response -e dns.qry.type"

if [ `whoami` != "root" ]
then
    echo "This script needs root privileges"
    exit 1
fi

#ifconfig $INTERFACE down
#iwconfig $INTERFACE mode monitor
#ifconfig $INTERFACE up
iwconfig $INTERFACE channel $CHANNEL

if [[ ! -f "$OUT_FILE" ]]; then
    touch "$OUT_FILE"
    sqlite3 "$OUT_FILE" <<< "
CREATE TABLE DNS (TIMESTAMP real,MAC_SRC,MAC_DST,IP_SRC,IP_DST,URL,DNS_RESPONSE int,DNS_QRY_TYPE);"
fi

echo "Process PID : $$"

eval $CAPTURE_PROGR $CAPTURE_FLAGS |
    eval $FILTER_PROGR "$FILTER_FLAGS" |
    #tee /dev/fd/2 |
    while IFS='|' read TIMESTAMP MAC_SRC MAC_DST IP_SRC IP_DST PROTOCOL URL DNS_RESPONSE DNS_QRY_TYPE; do
        if [[ "$PROTOCOL" = "DNS" && ("$DNS_QRY_TYPE" = "1" || "$DNS_QRY_TYP" = "28") ]]; then
            echo "INSERT INTO DNS VALUES ('$TIMESTAMP', '$MAC_SRC', '$MAC_DST', '$IP_SRC','$IP_DST','$URL','$DNS_RESPONSE', '$DNS_QRY_TYPE');"
	    printf "%10s %20s %20s %15s %15s %-3s %-s\n" "$(date -d @${TIMESTAMP} '+%H:%M:%S')" "$MAC_SRC" "$MAC_DST" "$IP_SRC" "$IP_DST" "$PROTOCOL" "$URL" >/dev/stderr
    done |
    sqlite3 "$OUT_FILE"
