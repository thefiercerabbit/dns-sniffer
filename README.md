# dns-sniffer
## In brief
This is a very simple script sniffing and decrypting DNS traffic of a WLAN network.

## History
Previously, the script was using both *dumpcap* and *tshark*, the former for the capture, the latter for the decryption and filtering.
However, *dumpcap* was unusable for long time capture because of its memory consumption (see [here](https://wiki.wireshark.org/KnownBugs/OutOfMemory)).
Thus the use of *decrypt11dot*, which does the job perfectly.
Also, *tshark* was replace by *tcpdump*, a bit more efficient for easy tasks like printing MAC and IP adrresses, or requested URLs.

## Usage
You will need *tcpdump*, [dot11decrypt](https://github.com/mfontanini/dot11decrypt) and a network adapter in *monitor mode*.
Replace the first fields of the script by your own network parameters (encrypion, SSID, password, channel), update the interface, log and database files.
Launch has root.

A basic *systemd* service file has been included, for those who may need a startup daemon (see *systemd* for your distribution).