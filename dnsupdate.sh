#!/bin/bash

function _exit_function() {
    kill -9 0
}

trap "_exit_function" 0

INTERFACE="wlan0"
OUT_FILE="/temp/dns.db"
OPTIONS="w:i:"

SSID="MyRouter"
PASSWORD="MyPassword"
CHANNEL="6"
RTR_MAC="01:23:45:67:89:AB"

while getopts $OPTIONS opt; do
    case $opt in
	'w' ) OUT_FILE="$OPTARG" ;;
	'i' ) INTERFACE="$OPTARG";;
	* ) exit;;
    esac
done

CAPTURE_PROGR='dumpcap'
CAPTURE_FLAGS="-q -i $INTERFACE -I -f '(link[0] != 0x80) and (wlan ra $RTR_MAC or wlan ta $RTR_MAC or wlan host $RTR_MAC)' -w -"
FILTER_PROGR='tshark'
FILTER_FLAGS="-l -o wlan.enable_decryption:TRUE -o 'uat:80211_keys:\"wpa-pwd\",\"${PASSWORD}:${SSID}\"' -r - -Y '(dns) or (bootp.option.type==53)' -Tfields -E separator='|' -e frame.time_epoch -e wlan.ta -e wlan.ra -e ip.src -e ip.dst -e bootp.id -e bootp.option.requested_ip_address -e dns.qry.name -e _ws.col.Protocol -e dns.flags.response -e dns.qry.class -e dns.qry.type "

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
CREATE TABLE DNS (TIMESTAMP real,TA,RA,IP_SRC,IP_DST,URL,DNS_RESPONSE int,DNS_QRY_CLASS,DNS_QRY_TYPE);
CREATE TABLE DHCP(TIMESTAMP real,TA,RA,IP_SRC,IP_DST,IP_REQUEST,BOOTP_ID);"
fi

echo "Process PID : $$"
eval $CAPTURE_PROGR $CAPTURE_FLAGS |
    eval $FILTER_PROGR "$FILTER_FLAGS" |
    #tee /dev/fd/2 |
    while IFS='|' read TIMESTAMP TA RA IP_SRC IP_DST BOOTP_ID IP_REQUEST URL PROTOCOL DNS_RESPONSE DNS_QRY_CLASS DNS_QRY_TYPE; do
        if [[ "$PROTOCOL" = "DNS" ]]; then
            echo "INSERT INTO DNS VALUES ('$TIMESTAMP', '$TA', '$RA', '$IP_SRC','$IP_DST','$URL','$DNS_RESPONSE', '$DNS_QRY_CLASS', '$DNS_QRY_TYPE');"
	    printf "%10s %20s %20s %15s %15s %-5s %s\n" "$(date -d @${TIMESTAMP} '+%H:%M:%S')" "$TA" "$RA" "$IP_SRC" "$IP_DST" "$PROTOCOL" "$URL" >/dev/stderr
        elif [[ "$PROTOCOL" = "DHCP" ]]; then
            echo "INSERT INTO DHCP VALUES ('$TIMESTAMP', '$TA', '$RA', '$IP_SRC','$IP_DST', '$IP_REQUEST', '$BOOTP_ID');"
	    printf "%10s %20s %20s %15s %15s %-5s %s\n" "$(date -d @${TIMESTAMP} '+%H:%M:%S')" "$TA" "$RA" "$IP_SRC" "$IP_DST" "$PROTOCOL" "$IP_REQUEST" >/dev/stderr
        else
	    printf "%10s %20s %20s %15s %15s %-5s\n" "$(date -d @${TIMESTAMP} "+%H:%M:%S")" "$TA" "$RA" "$IP_SRC" "$IP_DST" "$PROTOCOL"  >/dev/stderr
	fi
    done |
    sqlite3 "$OUT_FILE"  
