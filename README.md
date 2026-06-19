# ASIX AX88179 DKMS driver

This program installs the original ASIX AX88179 driver from [manufacturer's website][1] using [DKMS](https://github.com/dell/dkms).

Installing the original driver may be required when a compatible driver loaded by a Linux distro lacks support for AX88179 features, such as full-duplex mode for 1Gb/s connections.

## How to install

1. Clone this repository and make it the working directory:
```
git clone https://github.com/FlorianLaunay/asix-ax88179-dkms.git
cd asix-ax88179-dkms
```

2. (Optional step) Navigate to [AX88179 product page][1] and download the Linux driver. Copy the downloaded tarball path into the clipboard for the next step.

3. Run the installation program to download, build and install the driver.
```
sudo ./install.sh
```

To install from an existing tarball (downloaded in optional step 2), specify the tarball path as its last argument. E.g.:
```
sudo ./install.sh ~/Downloads/ASIX_USB_NIC_Linux_Driver_Source_v4.1.0.tar.bz2
```

4. Unplug your USB device with ASIX AX88179. Wait a few seconds. Plug it back in.

5. Verify that your USB device with ASIX AX88179 is now managed by its original driver:
```
lsusb -vt | grep -B1 AX88179
```
Which should report `Driver=ax_usb_nic`:
```
        |__ Port 004: Dev 004, If 0, Class=Vendor Specific Class, Driver=ax_usb_nic, 5000M
            ID 0b95:1790 ASIX Electronics Corp. AX88179 Gigabit Ethernet
```

6. (Optional step) Enable Ethernet jumbo frames for ASIX AX88179 connections.
For maximum compatibility with existing network hardware, jumbo frames are not enabled by default in switches/routers or NICs. To make use of jumbo frames, they must be explicitly enabled in your router/switch, and in the network connection settings of the both IP src/dst peers.

AX88179 supports jumbo frames with (IP Maximum Transmission Unit) MTU=9216. In KDE Plasma, enabling Ethernet jumbo frames involves setting MTU=9216 in the "WiFi & Networking -> <connection-name> -> Wired" tab, and reconnecting.

Setting MTU=9216 only _enables_ using larger Ethernet frames. The IP path MTU discovery finds the actual MTU of the particular network path between the IP src/dst peers, and adjusts the MTU down to prevent sending large IP packets that would have to be fragmented somewhere along the path.

To verify whether Ethernet jumbo frames are enabled:
```
ip -d addr
```
Which should report `mtu 9216` for the IP link, matching `maxmtu 9216` of its Ethernet link, e.g.:
```
...
3: enx6...2: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9216 qdisc fq_codel state UP group default qlen 1000
    link/ether ... brd ... promiscuity 0  allmulti 0 minmtu 68 maxmtu 9216 numtxqueues 1 numrxqueues 1 gso_max_size 16384 gso_max_segs 65535 tso_max_size 16384 tso_max_segs 65535 gro_max_size 65536 parentbus usb parentdev 4-1.4:1.0
    inet 10.0.0.3/24 brd 10.0.0.255 scope global dynamic noprefixroute enx6...2
       valid_lft 580108sec preferred_lft 580108sec
...
```

In a 2.5Gb/s LAN, with jumbo frames enabled in the router and the peers, the maximum ASIX AX88179 data transfer rate reported by `iperf3 -VNZ --bidir -w8M --dont-fragment -c <server>` is:

* ~933kb/s with the default Ethernet frame MTU=1500,
* ~950kb/s (+1.8%) with Ethernet jumbo frame MTU=9216.

## How to uninstall

1. Run the installation program with the uninstall option. If necessary, specify the existing tarball path as its last argument:
```
sudo ./install.sh -u [<path-to-source-tarball>]
```

## Licence

Please see [LICENCE](LICENCE).

[1]: https://www.asix.com.tw/en/product/USBEthernet/Super-Speed_USB_Ethernet/AX88179A
