# dns-sniffer
This is a very simple script sniffing DNS traffic of a local network.
You will need *tshark* and a network adapter in *monitor mode*. If you are sniffing WiFi traffic, configure your adapter to listen to the right channel.

# Why is it different ?
*tshark* needs to read from a capture file. Even if you're not recording any event, but just displaying some stuff, *tshark* creates a temp file (generaly in */tmp*) which can get pretty big after some time... This script launches *dumpcap* on its own, and use a pipe redirection to avoid the creation of a temp file.
This feature was compulsory for me, since it runs on a Raspberry Pi 2 with very few memory. Moreover, if some other hack would have been possible with the "ring buffer" option of *dumpcap*/*tshark*, it would still need to do IO operations on the disk (USB key in my case). Here, the redirected stdout fits in RAM.

