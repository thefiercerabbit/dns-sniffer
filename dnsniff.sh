#!/bin/bash

ENC="wpa"
SSID="VM5954666"
PWD="ty2kkGgwvgvd"
INTERFACE="wlan1"
CHANNEL="11"

DB_FILE="/home/pi/dns.db"

function _kill_all() {
#    [ -n "$$" ] && ((ps -p $$ 2>&1 > /dev/null) || (kill -2 $$ 2>/dev/null || kill -9 $$))
    [ -n "$CPID" ] && ((ps -p $CPID 2>&1 > /dev/null) ||  (kill -2 $CPID 2>&1 >/dev/null || kill -9 $CPID)) && wait $CPID
}

trap "_kill_all" 0

DOT11DECRYPT_PREFIX="/home/pi/dot11decrypt/build/"

if [ `whoami` != "root" ]
then
    echo "This script needs root privileges"
    exit 1
fi

ifconfig $INTERFACE down
iwconfig $INTERFACE mode monitor
ifconfig $INTERFACE up
iwconfig $INTERFACE channel $CHANNEL
ifconfig $INTERFACE up

if [[ ! -f "$DB_FILE" ]]; then
    touch "$DB_FILE"
    sqlite3 "$DB_FILE" <<< "
CREATE TABLE DNS (TIMESTAMP real,MAC_SRC,MAC_DST,IP_SRC,IP_DST,URL);"
fi


${DOT11DECRYPT_PREFIX}/dot11decrypt $INTERFACE "${ENC}:${SSID}:${PWD}" 2>/dev/null &
CPID=$!
echo "Process $CPID launched in background" > /dev/stderr

while ! [ -e "/sys/class/net/tap0" ]; do sleep 1; done

tcpdump -tt -n -e -l -s 0 -i tap0 dst port 53 |
    gawk 'match($0,/^(\w+\.\w+) ([0-9a-f:]{17}) > ([0-9a-f:]{17}).* (\w+\.\w+\.\w+\.\w+)\.\w+ > (\w+\.\w+\.\w+\.\w+).*\? (.*)\. .*?$/,g) {
    printf "%18s %17s %17s %15s %15s %-s\n",g[1],g[2],g[3],g[4],g[5],g[6] >> "dns.log"; fflush("dns.log");
    printf "%10s %17s %17s %15s %15s %-s\n",strftime("%D %T",g[1]),g[2],g[3],g[4],g[5],g[6] > "/dev/stderr"; fflush("/dev/stderr");
    printf "INSERT INTO DNS VALUES (\"" g[1]"\",\""g[2]"\",\""g[3]"\",\""g[4]"\",\""g[5]"\",\""g[6]"\");\n" > "/dev/stdout"; fflush("/dev/stdout");}' |
    sqlite3 $DB_FILE
