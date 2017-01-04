
function _exit_function() {
    kill -9 0
}

trap "_exit_function" 0

INTERFACE="wlan0"
CHANNEL="11"
OUT_FILE="/home/$USER/dns.db"
OPTIONS="w:i:"
RTR_MAC="XX:XX:XX:XX:XX:XX"
PASSWORD="password1234"
CAPTURE_PROGR='dumpcap'
CAPTURE_FLAGS="-q -i $INTERFACE -I -f '(link[0] != 0x80) and (wlan ra $RTR_MAC or wlan ta $RTR_MAC or wlan host $RTR_MAC)' -w -"
FILTER_PROGR='tshark'
FILTER_FLAGS="-l -o wlan.enable_decryption:TRUE -o 'uat:80211_keys:\"wep\",\"$PASSWORD\"' -r - -Y '(dns.flags.response==0 and dns.qry.type==1) or (bootp.option.type==53)' -Tfields -E separator='|' -e wlan.sa -e ip.src -e ip.dst -e bootp.id -e dns.qry.name -e frame.time_epoch -e _ws.col.Protocol"

if [ `whoami` != "root" ]
then
    echo "This script needs root privileges"
    exit 1
fi

while getopts $OPTIONS opt; do
    case $opt in
	'w' ) OUT_FILE="$OPTARG" ;;
	'i' ) INTERFACE="$OPTARG";;
	* ) exit;;
    esac
done

ifconfig $INTERFACE down
iwconfig $INTERFACE mode monitor
ifconfig $INTERFACE up
iwconfig $INTERFACE channel $CHANNEL

if [[ ! -f "$OUT_FILE" ]]; then
    touch "$OUT_FILE"
    sqlite3 "$OUT_FILE" <<< "CREATE TABLE LOG (MAC_ADDR,IP_SRC,IP_DST,URL,TIMESTAMP,PROTOCOL);"
fi

echo "Process PID : $$"
eval $CAPTURE_PROGR $CAPTURE_FLAGS |
    eval $FILTER_PROGR "$FILTER_FLAGS" |
    tee /dev/fd/2 |
    while IFS='|' read MAC_ADDR IP_SRC IP_DST BOOTP_ID URL TIMESTAMP PROTOCOL; do
	if [[ -n "$BOOTP_ID" ]]; then
	    echo "INSERT INTO LOG VALUES ('$MAC_ADDR','$IP_SRC','$IP_DST','$BOOTP_ID','$TIMESTAMP','$PROTOCOL');"
	else
	    echo "INSERT INTO LOG VALUES ('$MAC_ADDR','$IP_SRC','$IP_DST','$URL','$TIMESTAMP','$PROTOCOL');"
	fi
    done |
    sqlite3 "$OUT_FILE"
