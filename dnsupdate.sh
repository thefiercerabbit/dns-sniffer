#!/bin/bash

MAC_OUT="internet_world_mac_addr"
MAC_IN="local_network_mac_addr"
BSSID="your_bssid"
PASSWORD="your_wifi_password"
CAPTURE_PROGR='dumpcap'
CAPTURE_FLAGS="-q -i wlan0 -I -f '(link[0] != 0x80) and ((wlan ra $MAC_IN) or (wlan ta $MAC_IN) or (wlan ra $MAC_OUT) or (wlan ta $MAC_OUT))' -w -"
FILTER_PROGR='tshark'
FILTER_FLAGS="-l -o wlan.enable_decryption:TRUE -o 'uat:80211_keys:\"wpa-pwd\",\"$PASSWORD:$BSSID\"' -r - -Y '(dns.flags.response==0 and dns.qry.type==1) or (bootp.option.type==53)' -Tfields -E separator='|' -e wlan.sa -e ip.src -e ip.dst -e bootp.id -e dns.qry.name -e frame.time_epoch -e _ws.col.Protocol"

if [ `whoami` != "root" ]
then
        sudo -s "$0" "$@"
        if [ $? -ne 0 ] ; then
            echo "This script need root privileges"
            exit 1
        fi
	exit 0
fi


eval "$CAPTURE_PROGR $CAPTURE_FLAGS" | eval "$FILTER_PROGR $FILTER_FLAGS" |
while IFS='|' read MAC_ADDR IP_SRC IP_DST BOOTP_ID URL TIMESTAMP PROTOCOL; do
    if [[ -n "$BOOTP_ID" ]]; then
	echo "INSERT INTO LOG VALUES ('$MAC_ADDR','$IP_SRC','$IP_DST','$BOOTP_ID','$TIMESTAMP','$PROTOCOL');"
    else
	echo "INSERT INTO LOG VALUES ('$MAC_ADDR','$IP_SRC','$IP_DST','$URL','$TIMESTAMP','$PROTOCOL');"
    fi
done
