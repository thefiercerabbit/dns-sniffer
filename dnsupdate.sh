#!/bin/bash

PSK="0d096bac38bc72b10dbb91b9735f39f84b5a991d0d63fefe11f9e05d6dcbc341"
CAPTURE_PROGR='tshark'
CAPTURE_FLAGS='-l -o wlan.enable_decryption:TRUE -o "uat:80211_keys:\"wpa-psk\",\"$PSK\"" -Y "(dns.flags.response==0 and dns.qry.type==1) or (bootp)" -Tfields -E "separator=|" -e "wlan.sa" -e "ip.src" -e "ip.dst" -e "bootp.id" -e "dns.qry.name" -e "frame.time_epoch" -e "_ws.col.Protocol" -q -i wlan0'

if [ `whoami` != "root" ]
then
        sudo -s "$0" "$@"
        if [ $? -ne 0 ] ; then
            echo "This script need root privileges"
            exit 1
        fi
	exit 0
fi


eval "$CAPTURE_PROGR $CAPTURE_FLAGS" |
while IFS='|' read MAC_ADDR IP_SRC IP_DST BOOTP_ID URL TIMESTAMP PROTOCOL; do
    if [[ -n "$BOOTP_ID" ]]; then
	echo -e "$MAC_ADDR\t$IP_SRC\t$IP_DST\t$BOOTP_ID\t$TIMESTAMP\t$PROTOCOL"
    else
	echo -e "$MAC_ADDR\t$IP_SRC\t$IP_DST\t$URL\t$TIMESTAMP\t$PROTOCOL"
    fi
done
