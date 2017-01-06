function _exit_function() {
    kill -9 0
}

trap "_exit_function" 0

# Your interface should already be in monitor mode,
# otherwise add -I option to the capture flags.
# One could also change the mode before setting the channel (see below).
INTERFACE="wlan0mon" 
OUT_FILE="/tmp/dns.db" # Change if you want your file to be saved after reboot.

SSID="YourBox"
PASSWORD="YourPassword"
CHANNEL="3"
RTR_MAC="01:23:45:67:89:AB"

OPTIONS="w:i:"
while getopts $OPTIONS opt; do
    case $opt in
	'w' ) OUT_FILE="$OPTARG" ;;
	'i' ) INTERFACE="$OPTARG";;
	* ) exit;;
    esac
done

CAPTURE_PROGR='dumpcap'
CAPTURE_FLAGS="-q -i $INTERFACE -f '(link[0] != 0x80) and (wlan ra $RTR_MAC or wlan ta $RTR_MAC or wlan host $RTR_MAC)' -w -"
FILTER_PROGR='tshark'
FILTER_FLAGS="-l -o wlan.enable_decryption:TRUE -o 'uat:80211_keys:\"wpa-pwd\",\"${PASSWORD}:${SSID}\"' -r - -Y '(dns) or (bootp.option.type==53)' -Tfields -E separator='|' -e frame.time_epoch -e wlan.ta -e wlan.ra -e ip.src -e ip.dst -e bootp.id -e bootp.option.requested_ip_address -e dns.qry.name -e _ws.col.Protocol -e dns.flags.response -e dns.qry.class -e dns.qry.type "

if [ `whoami` != "root" ]
then
    echo "This script needs root privileges"
    exit 1
fi

# ifconfig $INTERFACE down
# iwconfig $INTERFACE mode monitor
# ifconfig $INTERFACE up
iwconfig $INTERFACE channel $CHANNEL

if [[ ! -f "$OUT_FILE" ]]; then
    touch "$OUT_FILE"
    sqlite3 "$OUT_FILE" <<< "
CREATE TABLE DNS (TIMESTAMP,TA,RA,IP_SRC,IP_DST,URL,DNS_RESPONSE,DNS_QRY_CLASS,DNS_QRY_TYPE);
CREATE TABLE DHCP (TIMESTAMP,TA,RA,IP_SRC,IP_DST,IP_REQUEST,BOOTP_ID);"
fi

echo "Process PID : $$"
eval $CAPTURE_PROGR $CAPTURE_FLAGS |
    eval $FILTER_PROGR "$FILTER_FLAGS" |
    tee /dev/fd/2 |
    while IFS='|' read TIMESTAMP TA RA IP_SRC IP_DST BOOTP_ID IP_REQUEST URL PROTOCOL DNS_RESPONSE DNS_QRY_CLASS DNS_QRY_TYPE; do
        if [[ "$PROTOCOL" = "DNS" ]]; then
            echo "INSERT INTO DNS VALUES ('$TIMESTAMP', '$TA', '$RA', '$IP_SRC','$IP_DST','$URL','$DNS_RESPONSE', '$DNS_QRY_CLASS', '$DNS_QRY_TYPE');"
        else
            echo "INSERT INTO DHCP VALUES ('$TIMESTAMP', '$TA', '$RA', '$IP_SRC','$IP_DST', '$IP_REQUEST', '$BOOTP_ID');"
        fi
    done |
    sqlite3 "$OUT_FILE"
