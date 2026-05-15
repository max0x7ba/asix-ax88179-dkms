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

## How to uninstall

1. Run the installation program with the uninstall option. If necessary, specify the existing tarball path as its last argument:
```
sudo ./install.sh -u [<path-to-source-tarball>]
```

## Licence

Please see [LICENCE](LICENCE).

[1]: https://www.asix.com.tw/en/product/USBEthernet/Super-Speed_USB_Ethernet/AX88179A
