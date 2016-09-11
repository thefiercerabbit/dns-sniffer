# dns-sniffer
This is a very simple script sniffing DNS traffic of a local network.
You will need *tshark* and a network adapter in *monitor mode*. If you are a sniffing WiFi, configure your adapter to listen to the right channel.
DHCP packets are also logged, so you can check when some client has joined the network, which local IP it has been given, etc...
