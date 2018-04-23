---
title: Installing Windows 10 over PXE with dnsmasq, pxelinux and WinPE
tags: [network, windows]
date: 2018-04-15
language: en
...

So I needed to install Windows 10 on some laptop - without optical
drive - here.  I downloaded the iso from Microsoft, used `dd` to copy
it to an SD card and tried to boot from it - without success.  After
various attempts to fix booting from SD (or USB) on that laptop with
that (non-damaged) iso I decided to go a bit further:

## Overview

The approach I ended up with needs some systems / servers to play
nicely together.  First of all, I connected the laptop directly per an
ethernet cable to a NixOS machine.

*What happens at boot?*

 - The laptop boots, PXE ("network boot") selected as primary boot
   option.
 - The BIOS tries to get an IP address and a "boot-filename" via DHCP.
 - The BIOS tries to connect to a [TFTP][wiki-tftp] server and
   download a file with the boot-filename.  It then boots that file.
 - That file should be a special bootloader, [pxelinux][] in my case,
   which uses TFTP to load further program modules, especially the
   [memdisk][] module.
 - The bootloader boots the memdisk module.  This loads a special
   minimalistic windows operating system called ["Windows PE"][winpe]
   or short "WinPE" into main memory (over TFTP) and boots it.
 - WinPE runs `wpeinit` to detect hardware, followed by `ipconfig` to
   get network settings via DHCP.
 - WinPE can now access a [SMB network drive][wiki-smb] which contains
   the files from the Windows install iso and run `setup.exe` to start
   the installation.

[wiki-tftp]: https://en.wikipedia.org/wiki/Trivial_File_Transfer_Protocol
[pxelinux]: https://www.syslinux.org/wiki/index.php?title=PXELINUX
[memdisk]: https://www.syslinux.org/wiki/index.php?title=MEMDISK
[winpe]: https://en.wikipedia.org/wiki/Windows_Preinstallation_Environment
[wiki-smb]: https://en.wikipedia.org/wiki/Server_Message_Block

*What's needed?*

 - A DHCP server supporting PXE.  [(ISC-)dhcpd][wiki-dhcpd]
   [works][debian-dhcpd-pxe] but [dnsmasq][wiki-dnsmasq] is a much
   better choice in my case because it also has a builtin TFTP server.
   It also supports [being a proxy][dnsmasq-proxy] DHCP server if
   there's already a DHCP server on the network which doesn't support
   PXE.
 - A TFTP server.  dnsmasq does this for me, but there's also
   tftp-hpa.
 - pxelinux and memdisk.  Both are often part of syslinux packages.
 - A compatible WinPE iso.  This can be created from the Windows
   install iso using [wimlib][].
 - A SMB/CIFS server.  I use [Samba][] on the NixOS machine, but a Windows
   server would do, too.

[wiki-dhcpd]: https://en.wikipedia.org/wiki/DHCPD
[debian-dhcpd-pxe]: https://www.debian.org/releases/stable/i386/ch04s05.html.en
[wiki-dnsmasq]: https://en.wikipedia.org/wiki/Dnsmasq
[dnsmasq-proxy]: https://wiki.archlinux.org/index.php/dnsmasq#PXE_server
[wimlib]: https://wimlib.net/
[samba]: https://www.samba.org/


## The firewall

Fighting against the my own firewall on the NixOS machine is
unnecessary, I just allow any traffic from the laptop:

~~~
iptables -I INPUT 1 -i eno1 -j ACCEPT
~~~

## The DHCP server

With nothing configured (except the BIOS of the laptop for network
boot) and the two systems connected by the ethernet cable it is
possible to check that the BIOS is actually looking for a DHCP server
by running `tcpdump -ttttnnvvS -i eno1` (where `eno1` is the -
unconfigured - ethernet network interface on the NixOS machine):

~~~
2018-04-15 15:25:14.037484 IP (tos 0x0, ttl 20, id 0, offset 0, flags [none], proto UDP (17), length 576)
    0.0.0.0.68 > 255.255.255.255.67: [udp sum ok] BOOTP/DHCP, Request from 20:6a:8a:0f:74:75, length 548, xid 0x8b0f7475, secs 4, Flags [Broadcast] (0x8000)
          Client-Ethernet-Address 20:6a:8a:0f:74:75
          Vendor-rfc1048 Extensions
            Magic Cookie 0x63825363
            DHCP-Message Option 53, length 1: Discover
            Parameter-Request Option 55, length 36: 
              Subnet-Mask, Time-Zone, Default-Gateway, Time-Server
              IEN-Name-Server, Domain-Name-Server, RL, Hostname
              BS, Domain-Name, SS, RP
              EP, RSZ, TTL, BR
              YD, YS, NTP, Vendor-Option
              Requested-IP, Lease-Time, Server-ID, RN
              RB, Vendor-Class, TFTP, BF
              Option 128, Option 129, Option 130, Option 131
              Option 132, Option 133, Option 134, Option 135
            MSZ Option 57, length 2: 1260
            GUID Option 97, length 17: 0.214.110.241.0.166.215.17.223.159.26.249.56.166.111.192.84
            ARCH Option 93, length 2: 0
            NDI Option 94, length 3: 1.2.1
            Vendor-Class Option 60, length 32: "PXEClient:Arch:00000:UNDI:002001"

~~~

This is a `BOOTP/DHCP` request (with a `DHCPDISCOVER` inside) from
`20:6a:8a:0f:74:75` with no IP address assigned (thus `0.0.0.0`) to
the broadcast address `255.255.255.255`.  It's sending from port `67`
(client side DHCP) to port `68` (server side DHCP) and asking for
various network parameters, including `BF` (the so called boot
filename) and `TFTP`.

Starting `dnsmasq -C dnsmasq.conf` with

~~~
port=0 # disable DNS server
interface=eno1
bind-interfaces
dhcp-option=3,192.168.42.1 # default gateway
dhcp-option=6,8.8.8.8,8.8.4.4 # dns servers
dhcp-range=192.168.42.10,192.168.42.20,12h
~~~

results in the NixOS machine answering:

~~~
2018-04-15 15:42:01.801824 IP (tos 0xc0, ttl 64, id 43076, offset 0, flags [none], proto UDP (17), length 328)
    192.168.42.1.67 > 255.255.255.255.68: [bad udp cksum 0xebee -> 0x8eff!] BOOTP/DHCP, Reply, length 300, xid 0x9c0f7475, secs 38, Flags [Broadcast] (0x8000)
          Your-IP 192.168.42.17
          Server-IP 192.168.42.1
          Client-Ethernet-Address 20:6a:8a:0f:74:75
          Vendor-rfc1048 Extensions
            Magic Cookie 0x63825363
            DHCP-Message Option 53, length 1: Offer
            Server-ID Option 54, length 4: 192.168.42.1
            Lease-Time Option 51, length 4: 43200
            RN Option 58, length 4: 21600
            RB Option 59, length 4: 37800
            Subnet-Mask Option 1, length 4: 255.255.255.0
            BR Option 28, length 4: 192.168.42.255
            Domain-Name-Server Option 6, length 8: 8.8.8.8,8.8.4.4
            Default-Gateway Option 3, length 4: 192.168.42.1

~~~

This offers an IP address (`192.168.42.17` here) to the laptop (mac
`20:6a:8a:0f:74:75`), sends DNS information, the default gateway and
some other stuff.  **But the BIOS ignores it** and keeps sending
`DHCPDISCOVER` requests.  That's because the reply - the `DHCPOFFER` -
doesn't include a boot-filename.  After some seconds the BIOS on the
laptop thus announces:

> PXE-E53 no boot filename received

To fix this, I need to tell dnsmasq to send a boot filename by adding
this to the config:

~~~
dhcp-boot=boot/pxelinux.0
~~~

Then, the exchange between the machines reads as follows:

~~~
2018-04-15 15:51:14.641613 IP (tos 0x0, ttl 20, id 5, offset 0, flags [none], proto UDP (17), length 576)
    0.0.0.0.68 > 255.255.255.255.67: [udp sum ok] BOOTP/DHCP, Request from 20:6a:8a:0f:74:75, length 548, xid 0x900f7475, secs 14, Flags [Broadcast] (0x8000)
          Client-Ethernet-Address 20:6a:8a:0f:74:75
// ...
            DHCP-Message Option 53, length 1: Discover
// ...

2018-04-15 15:51:15.558948 IP (tos 0xc0, ttl 64, id 12988, offset 0, flags [none], proto UDP (17), length 342)
    192.168.42.1.67 > 255.255.255.255.68: [bad udp cksum 0xebfc -> 0xc4bd!] BOOTP/DHCP, Reply, length 314, xid 0x8f0f7475, secs 12, Flags [Broadcast] (0x8000)
          Your-IP 192.168.42.17
          Server-IP 192.168.42.1
          Client-Ethernet-Address 20:6a:8a:0f:74:75
// ...
            DHCP-Message Option 53, length 1: Offer
// ...
            BF Option 67, length 16: "boot/pxelinux.0^@"
// ...

2018-04-15 15:51:16.728848 IP (tos 0x0, ttl 20, id 6, offset 0, flags [none], proto UDP (17), length 576)
    0.0.0.0.68 > 255.255.255.255.67: [udp sum ok] BOOTP/DHCP, Request from 20:6a:8a:0f:74:75, length 548, xid 0x900f7475, secs 14, Flags [Broadcast] (0x8000)
          Client-Ethernet-Address 20:6a:8a:0f:74:75
// ...
            DHCP-Message Option 53, length 1: Request
// ...

2018-04-15 15:51:16.821564 IP (tos 0xc0, ttl 64, id 13949, offset 0, flags [none], proto UDP (17), length 342)
    192.168.42.1.67 > 255.255.255.255.68: [bad udp cksum 0xebfc -> 0xc0bb!] BOOTP/DHCP, Reply, length 314, xid 0x900f7475, secs 14, Flags [Broadcast] (0x8000)
          Your-IP 192.168.42.17
          Server-IP 192.168.42.1
          Client-Ethernet-Address 20:6a:8a:0f:74:75
// ...
            DHCP-Message Option 53, length 1: ACK
// ...
            BF Option 67, length 16: "boot/pxelinux.0^@"

~~~

The replies from the NixOS DHCP server notably now contain the `BF`
option.  Moreover the complete Discover, Offer, Request, ACK cycle is
now complete - thus the laptop now has IP address `192.168.42.17`.

## The TFTP server, pxelinux and memdisk

Next, the BIOS asks (via `ARP`) who's `192.168.42.1` (the DHCP server,
probably because it doesn't know better) and sends a TFTP `RRQ`
resource request for the boot filename.  The NixOS machine blocks the
request because there's (currently) no TFTP server running on it:

~~~
2018-04-15 15:51:16.823557 ARP, Ethernet (len 6), IPv4 (len 4), Request who-has 192.168.42.1 tell 192.168.42.17, length 46
2018-04-15 15:51:16.823576 ARP, Ethernet (len 6), IPv4 (len 4), Reply 192.168.42.1 is-at 34:e6:d7:1a:33:48, length 28
2018-04-15 15:51:16.823672 IP (tos 0x0, ttl 20, id 7, offset 0, flags [none], proto UDP (17), length 60)
    192.168.42.17.2070 > 192.168.42.1.69: [udp sum ok]  32 RRQ "boot/pxelinux.0" octet tsize 0
2018-04-15 15:51:16.823755 IP (tos 0xc0, ttl 64, id 28676, offset 0, flags [none], proto ICMP (1), length 88)
    192.168.42.1 > 192.168.42.17: ICMP 192.168.42.1 udp port 69 unreachable, length 68
~~~

After numerous tries the BIOS then fails with the error message:

> PXE-E32: TFTP open timeout

So I add this to `dnsmasq.conf`:

~~~
enable-tftp
tftp-root=/tmp/win-pxe/tftp
~~~

Also I create a file `/tmp/win-pxe/tftp/boot/pxelinux.cfg/default`:

~~~ini
UI         menu.c32
MENU TITLE Network Boot
TIMEOUT    50

LABEL      winpe
MENU LABEL Boot Windows PE from network
KERNEL     /memdisk
INITRD     winpe.iso
APPEND     iso raw

LABEL      localboot
MENU LABEL Boot from local disk
LOCALBOOT  0
~~~

Turning the laptop on again now boots pxelinux with the menu, given
that the required files are in `/tmp/win-pxe-tftp/`:

~~~
dnsmasq: started, version 2.78 DNS disabled
dnsmasq: compile time options: IPv6 GNU-getopt DBus no-i18n IDN DHCP DHCPv6 no-Lua TFTP conntrack ipset auth DNSSEC loop-detect inotify
dnsmasq-dhcp: DHCP, IP range 192.168.42.10 -- 192.168.42.20, lease time 12h
dnsmasq-dhcp: DHCP, sockets bound exclusively to interface eno1
dnsmasq-tftp: TFTP root is /tmp/win-pxe/tftp 
dnsmasq-dhcp: DHCPDISCOVER(eno1) 20:6a:8a:0f:74:75 
dnsmasq-dhcp: DHCPOFFER(eno1) 192.168.42.17 20:6a:8a:0f:74:75 
dnsmasq-dhcp: DHCPREQUEST(eno1) 192.168.42.17 20:6a:8a:0f:74:75 
dnsmasq-dhcp: DHCPACK(eno1) 192.168.42.17 20:6a:8a:0f:74:75 
dnsmasq-tftp: error 0 TFTP Aborted received from 192.168.42.17
dnsmasq-tftp: failed sending /tmp/win-pxe/tftp/boot/pxelinux.0 to 192.168.42.17
dnsmasq-tftp: sent /tmp/win-pxe/tftp/boot/pxelinux.0 to 192.168.42.17
dnsmasq-tftp: sent /tmp/win-pxe/tftp/boot/ldlinux.c32 to 192.168.42.17
dnsmasq-tftp: file /tmp/win-pxe/tftp/boot/pxelinux.cfg/d66ef100-a6d7-11df-9f1a-f938a66fc054 not found
dnsmasq-tftp: file /tmp/win-pxe/tftp/boot/pxelinux.cfg/01-20-6a-8a-0f-74-75 not found
dnsmasq-tftp: file /tmp/win-pxe/tftp/boot/pxelinux.cfg/C0A82A11 not found
dnsmasq-tftp: file /tmp/win-pxe/tftp/boot/pxelinux.cfg/C0A82A1 not found
dnsmasq-tftp: file /tmp/win-pxe/tftp/boot/pxelinux.cfg/C0A82A not found
dnsmasq-tftp: file /tmp/win-pxe/tftp/boot/pxelinux.cfg/C0A82 not found
dnsmasq-tftp: file /tmp/win-pxe/tftp/boot/pxelinux.cfg/C0A8 not found
dnsmasq-tftp: file /tmp/win-pxe/tftp/boot/pxelinux.cfg/C0A not found
dnsmasq-tftp: file /tmp/win-pxe/tftp/boot/pxelinux.cfg/C0 not found
dnsmasq-tftp: file /tmp/win-pxe/tftp/boot/pxelinux.cfg/C not found
dnsmasq-tftp: sent /tmp/win-pxe/tftp/boot/pxelinux.cfg/default to 192.168.42.17
dnsmasq-tftp: sent /tmp/win-pxe/tftp/boot/menu.c32 to 192.168.42.17
dnsmasq-tftp: sent /tmp/win-pxe/tftp/boot/libutil.c32 to 192.168.42.17
dnsmasq-tftp: sent /tmp/win-pxe/tftp/boot/pxelinux.cfg/default to 192.168.42.17
~~~

## Wait ... `winpe.iso`?

This is where wimlib comes into play.  That's a library (and set of
programs) that work with Windows Imaging files.  It contains
`mkwinpeimg` which allows to create a (even customized) WinPE iso from
either a Windows install iso or a "Windows Automated Installation Kit
(WAIK)".  I use a Windows install iso.  I mount the iso to be able to
access its contents:

~~~
mount -o loop,ro /tmp/isos/Win10_1709_German_x64.iso /tmp/win10iso/
~~~

I also create a `start.cmd` script to define what's happening once
Windows PE boots:

~~~ini
cmd.exe
pause
~~~

Then I can create the WinPE iso:

~~~
mkwinpeimg --iso --windows-dir=/tmp/win10iso \
  --start-script=/tmp/win-pxe/start.cmd /tmp/winpe.iso
~~~

This first failed with an unexpected error (I have lots of free disk
space):

~~~
// ...
[ERROR] Error writing raw data to WIM file: No space left on device                                                                                              [BUSY] 
ERROR: Exiting with error code 72:
       Failed to write data to a file.

~~~

An educated guess later I decided to explicitly specify a temporary
directory on my disk (with much of free space) by adding
`--tmp-dir=/home/mustersel/temporary` to the `mkwinpeimg` command
line.  This gives me a `winpe.iso` file with a size of about 316M,
which I place in `/tmp/win-pxe/boot/`.



## Booting WinPE

On the laptop, I select "Boot Windows PE from network".  This causes
the memdisk module to be sent via TFTP:

~~~
dnsmasq-tftp: sent /tmp/win-pxe/tftp/boot//memdisk to 192.168.42.17
~~~

Then on the laptop memdisk shows:

> Loading winpe.iso

Looking at the NixOS machine reveals that memdisk loads `winpe.iso`
also via TFTP (which is a rather slow protocol, so this takes some
time):

~~~
dnsmasq-tftp: sent /tmp/win-pxe/tftp/boot/winpe.iso to 192.168.42.17
~~~

The laptop then greets me with some Windows loading screen, followed
by a command line.


## On WinPE in `cmd.exe`

According to the [ArchWiki page on Windows PE][arch-wiki-winpe] I need
to run the following once I'm on the Windows command line:

~~~
wpeinit
ipconfig
~~~

According to [some Microsoft page][wpeinit-microsoft] `wpeinit` "[..]
installs Plug and Play devices, [..], and loads network resources".
`ipconfig` [seems to be][ipconfig-wiki] the equivalent to `ifconfig`,
run without arguments it probably set up networking.  After running
these commands I could see on the NixOS machine how the laptop running
WinPE requested an IP via DHCP.  Note the hostname `minint-t10cd8a`
that is logged - it's no longer the BIOS doing the DHCP but the WinPE
environment:

~~~
dnsmasq-dhcp: DHCPDISCOVER(eno1) 20:6a:8a:0f:74:75 
dnsmasq-dhcp: DHCPOFFER(eno1) 192.168.42.17 20:6a:8a:0f:74:75 
dnsmasq-dhcp: DHCPREQUEST(eno1) 192.168.42.17 20:6a:8a:0f:74:75 
dnsmasq-dhcp: DHCPACK(eno1) 192.168.42.17 20:6a:8a:0f:74:75 minint-t10cd8a
~~~

For the next steps WinPE needs access to all of the Windows install
iso.

[arch-wiki-winpe]: https://wiki.archlinux.org/index.php/Windows_PE
[wpeinit-microsoft]: https://docs.microsoft.com/de-de/windows-hardware/manufacture/desktop/wpeinit-and-startnetcmd-using-winpe-startup-scripts
[ipconfig-wiki]: https://en.wikipedia.org/wiki/Ipconfig


# The Samba server

Setting up a SMB/CIFS network drive with Samba is pretty easy.  I use
the following config, but most of it is actually unnecessary:

~~~ini
[global]
map to guest = Bad User # Required
workgroup = home
log level = 5
unix extensions = No
client min protocol = SMB2
client max protocol = SMB3

min protocol = SMB2
max protocol = SMB3

state directory = /tmp/win-pxe/samba
pid directory = /tmp/win-pxe/samba
cache directory = /tmp/win-pxe/samba
lock directory = /tmp/win-pxe/samba

# "guest" in between [] is the name of the share
[guest]
path = /tmp/win10iso # Required
readonly = yes
guest ok = yes # Required

~~~

I can then "mount" this network drive from within WinPE with:

~~~
net use I:\\192.168.42.1\GUEST
~~~

This *should* make the contents of the Windows install iso (which is
mounted to `/tmp/win10iso` on the NixOS machine) available under `I:`
from WinPE.  But I ran into the following issue: On the NixOS machine
I got:

~~~
// ...
Server exit (NT_STATUS_CONNECTION_RESET)
Terminated
~~~

Basically Samba just died.  On the WinPE side the error message read:

~~~
System error 58 has occurred. The specified server cannot perform the requested operation
~~~

The solution is unintuitive but simple.  I just need to access the
network share with some username and password (doesn't matter which,
can be just random strings):

~~~
net use I: \\192.168.42.1\GUEST /user:user pass
~~~

I actually spent quite a lot of time searching for this solution, even
though it's right in the [ArchWiki page down at the
bottom][archwiki-winpe-err58]...

[archwiki-winpe-err58]: https://wiki.archlinux.org/index.php/Windows_PE#System_error_58_has_occurred._The_specified_server_cannot_perform_the_requested_operation


# Finally, the setup

~~~
I:\setup.exe
~~~

This starts the Windows install setup, which is guided and thus easy
to follow ... *until* it complained with a mysterical message that I
couldn't use the partitions I *just* created and formatted:

> We couldn't create a new partition or locate an existing one.  For
> more information, see the Setup log files.

After I [found][win-protocol-loc] (there were lots of files in these
directories - I just scrolled over them one after the other) these
"Setup log files" I noticed messages like these:

~~~
install drive does not meet requirements for installation
Couldn't find boot disk on this BIOS-based computer
~~~

The "solution" was to [remove the SD card][rem-sd-card] that still was
in the card reader from my attempts at booting Windows from that SD
card.  Apparently the Windows installer otherwise tries to install
Windows on that SD card instead of on the (just partioned)
drive. *Sigh.*


[rem-sd-card]: https://blogs.technet.microsoft.com/asiasupp/2012/03/06/error-we-couldnt-create-a-new-partition-or-locate-an-existing-one-for-more-information-see-the-setup-log-files-when-you-try-to-install-windows-8-cp/
[win-protocol-loc]: https://msdn.microsoft.com/de-de/library/windows/hardware/dn938373(v=vs.85).aspx

