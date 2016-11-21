Iterative tcpdump Script for RHELv7/CentOSv7
============================================

About
-----
This script will streamline the setup of a complex packet capturing routine.

Before running this script, be sure to configure and mount a secure storage device and otherwise approprately secure your system.

Detail
------
This script will guide the setup of a packet capturing machine and aid the setup of dependancies and security, including:
  - Restrictive iptables configuration, disable firewalld (if desired)
  - Dependency check/install:
    - tcpdump
    - date
  - Pcap target directory creation (if desired)
  - Permissions adjusting for the pcap target directory (if desired)


A series of questions will be asked to essentially fill in the following variables bash command:
  - date +'%Y-%m-%d_%H:%M:%S' | xargs -I {} bash -c "sudo tcpdump -q -i $interface -w $directory/{}$fileName.cap -C $fileSize -W $rolloverInt -Z root"


The output of this script will be files that appear as follows:

2016-05-24_16:45:26MyNetwork.cap0000

Where, 
  - "2016-05-24_16:45:26" is the date and time the tcpdump routine was inititated
  - "MyNetwork" is the name of the network you enter
  - "0000" is, a) the iteration number, and b) the number of digits required for your number of iterations

License
-------
Copyright © 2016 Lucas Walker

The bash code contained in this distribution is licensed under the Creative Commons BY-NC license.
