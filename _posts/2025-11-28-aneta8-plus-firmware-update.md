---
layout: post
title: "Anet A8 Plus - Firmware update - part 1"
date: 2025-11-28 00:00:00 +0000
author: Ben42Code
excerpt: A long path...already walked by many
---

* Table of content
{:toc}

# Context

My `Anet A8 Plus` came with outdated default firmware (likely a Markin 1.1.x fork), but it worked fine.

With the printer's large 300mm x 300mm bed, slight level variations still affected first-layer quality despite careful bed leveling. To address this, I wanted to enable Marlin's `MESH_BED_LEVELING` capabilities for better results on large prints.

# Disclaimer

This post doesn't offer anything really original—it's simply a recounting of my own experiences. I want to acknowledge and give full credit to the many Anet, Marlin, and 3D printing enthusiasts who paved the way long before me!

My initial entry point was this video [*Anet A8 (Plus) Marlin 2.0 Installation Upgrade*](https://www.youtube.com/watch?v=38PkynA1uGI) from Daniel's [Crosslink Youtube channel](https://www.youtube.com/@Crosslink3D). Thank you so much👍
<iframe width="210" height="160" src="http://www.youtube.com/embed/38PkynA1uGI" frameborder="0" allowfullscreen></iframe>
{: .shadowed_image}

# Requirements

## Motherboard version

Even though I think there's only one flavor of `Anet A8 Plus`, I have an `Anet V1.7` motherboard.

[![anet_v1.7](/assets/posts/2025-11-28-aneta8-plus-firmware-update/anet_v1.7.jpg){:height="100px" .shadowed_image}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/anet_v1.7.jpg)
[![anet_v1.7_logo](/assets/posts/2025-11-28-aneta8-plus-firmware-update/anet_v1.7_logo.jpg){:height="100px" .shadowed_image}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/anet_v1.7_logo.jpg)

## USBASP programmer

To make this process less painful, I do recommend few pieces of equipement to proceed. You can purchase those from your favorite online retailer for a very reasonable price. Those are very common.
- An USBASP programmer
- A 2x5 pins IDC ribbon cable
- An 10-pins to 6-pins ICSP adapter

Here are some of my purchases:
<table>
<tbody>
<tr>
<td><div markdown="1">
[![front](/assets/posts/2025-11-28-aneta8-plus-firmware-update/front.jpg){:width="100px" .shadowed_image}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/front.jpg)
</div></td>
<td><div markdown="1">
[![front](/assets/posts/2025-11-28-aneta8-plus-firmware-update/back.jpg){:width="100px" .shadowed_image}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/back.jpg)
</div></td>
<td><div markdown="1">
[![front](/assets/posts/2025-11-28-aneta8-plus-firmware-update/cable.jpg){:width="100px" .shadowed_image}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/cable.jpg)
</div></td>
</tr>
<tr>
<td><div markdown="1">
[![front](/assets/posts/2025-11-28-aneta8-plus-firmware-update/10x6_back.jpg){:width="100px" .shadowed_image}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/10x6_back.jpg)
</div></td>
<td><div markdown="1">
[![front](/assets/posts/2025-11-28-aneta8-plus-firmware-update/10x6_front.jpg){:width="100px" .shadowed_image}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/10x6_front.jpg)
</div></td>
<td><div markdown="1">
[![front](/assets/posts/2025-11-28-aneta8-plus-firmware-update/10x6_topbottom.jpg){:width="100px" .shadowed_image}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/10x6_topbottom.jpg)
</div></td>
</tr>
</tbody>
</table>
{:style="width: fit-content;"}

**Disclaimer**: All the USBASP programmers I purchased came with an outdated firmware. Leading to a well-documented (non-blocking) error message when you try to read/write the `Anet A8 Plus` firmware.
```
warning : Can not Set sck period . usbasp please check for firmware update .
```
**Not blocking** but it might slow down a bit the firmware transfer operations. It can be solved following these steps: [How to Upgrade Firmware in USBasp Programmer](https://www.youtube.com/watch?v=1tU7cAFwzig) from [Zero Amps Electronics Youtube channel](https://www.youtube.com/@zeroampselectronics).
<iframe width="210" height="160" src="http://www.youtube.com/embed/1tU7cAFwzig" frameborder="0" allowfullscreen></iframe>
{: .shadowed_image}
⚠️ To perform the USBASP programmer firmware update, you'll need another USBASP programmer! Since this device is really cheap, and just in case => do purchase at least 2 of them right away💵📦!

# Setup to read/write a Firmware

Here are the steps I've taken on a Windows 11 device.

## Install the USBASP programmer driver
I chose to leverage [Zadig](https://zadig.akeo.ie/).
- Download it from the product website <https://zadig.akeo.ie/>
- Install it
- Start it
- Plug your USBASP on your Windows device
- Enable the `Options / List All Devices` option.<br/>
![zadig_alldevices](/assets/posts/2025-11-28-aneta8-plus-firmware-update/zadig_alldevices.png){: .shadowed_image}
- Select the `USBASP` device
- Select the driver `WinUSB`. The version I got was `v6.1.7600.16385`. ⚠️I've read several post with different guidelines based on the OS version.
- Select `Install Driver`...since it's already installed on my device, I'm only proposed with its re-installation<br/>
![zadig_usbaspdriver](/assets/posts/2025-11-28-aneta8-plus-firmware-update/zadig_usbaspdriver.png){: .shadowed_image}

*Et voilà!*

![usbasp_devicepanel](/assets/posts/2025-11-28-aneta8-plus-firmware-update/usbasp_devicepanel.png){: .shadowed_image}

## Install AVRDUDESS

[`AVRDUDESS`](https://blog.zakkemble.net/avrdudess-a-gui-for-avrdude/) is a GUI for [`AVRDUDE`](https://github.com/avrdudes/avrdude)...if you're already familiar with [`AVRDUDE`](https://github.com/avrdudes/avrdude), it's a perfectly viable solution too.
- `AVRDUDESS` Github repo: <https://github.com/ZakKemble/AVRDUDESS>
- `AVRDUDESS` releases: <https://github.com/ZakKemble/AVRDUDESS/releases>

## Connect your USBASP...correctly

Here the whole device will now connect to our host device and to our 3D printer.

The `2x5 pins IDC ribbon cable` is keyed, you can't fail there...just beware that the 2x3 port of the `10-pins to 6-pins adapter` 🚨**is not keyed**⚠️, we'll need to be careful to connect it correctly to the `Anet A8 Plus` board.

[![10x6_notkeyed](/assets/posts/2025-11-28-aneta8-plus-firmware-update/10x6_notkeyed.jpg){:height="200px" .shadowed_image}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/10x6_notkeyed.jpg)

⚠️TODO⚠️
{: style="font-size: xx-large;font-weight: 900;color: red;"}


### On your host device

...just plug it on any USB port😅.

### On your Anet A8 Plus

We will be using the `J3` connector that exposes the [ATMega1284p](https://www.microchip.com/en-us/product/ATMEGA1284P) [SPI interface](https://en.wikipedia.org/wiki/Serial_Peripheral_Interface).

#### Where is the J3 connector

[![J3_location](/assets/posts/2025-11-28-aneta8-plus-firmware-update/J3_location.jpg){:height="200px" .shadowed_image}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/J3_location.jpg)
[![j3_plugged](/assets/posts/2025-11-28-aneta8-plus-firmware-update/j3_plugged.jpg){:height="200px" .shadowed_image}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/j3_plugged.jpg)
[![j3_unplugged](/assets/posts/2025-11-28-aneta8-plus-firmware-update/j3_unplugged.jpg){:height="200px" .shadowed_image}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/j3_unplugged.jpg)


#### ATMega1284p SPI pinout on the Anet A8 V1.7 board

From [`pins_ANET_10.h`](https://github.com/MarlinFirmware/Marlin/blob/fff0d703610199f1133ff1073ee21ef2269ebab7/Marlin/src/pins/sanguino/pins_ANET_10.h#L161-L172)  on [`Marlin@2.1.2.4`](https://github.com/MarlinFirmware/Marlin/tree/2.1.2.4):

```
       ------
  3V3 | 1  2 | SS
  GND | 3  4 | RESET
 MOSI | 5  6   SCK
   5V | 7  8 | MISO
J3_RX | 9 10 | J3_TX
       ------
         J3
```

`J3` connector on the `Anet V1.7` board:

[![J3_pinout](/assets/posts/2025-11-28-aneta8-plus-firmware-update/J3_pinout.jpg){:height="200px" .shadowed_image}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/J3_pinout.jpg)

From the [ATmega1280p documentation](https://ww1.microchip.com/downloads/en/DeviceDoc/8059S.pdf):

[![ATmega1280p-zoom](/assets/posts/2025-11-28-aneta8-plus-firmware-update/ATmega1284p-zoom.jpg){:height="200px" .shadowed_image}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/ATmega1284p-zoom.jpg)
[![ATmega1280p](/assets/posts/2025-11-28-aneta8-plus-firmware-update/ATmega1284p.jpg){:height="200px" .shadowed_image}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/ATmega1284p.jpg)

`ATmega1284p` on the `Anet V1.7` board:

[![ATmega1284p_anetv1.7](/assets/posts/2025-11-28-aneta8-plus-firmware-update/ATmega1284p_anetv1.7.jpg){:height="200px" .shadowed_image}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/ATmega1284p_anetv1.7.jpg)

#### SPI pinout on the 10x6 adapter

[![10x6_SPI_pinout](/assets/posts/2025-11-28-aneta8-plus-firmware-update/10x6_SPI_pinout.jpg){:height="200px" .shadowed_image}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/10x6_SPI_pinout.jpg)


#### Let's now plug it

⚠️TODO⚠️
{: style="font-size: xx-large;font-weight: 900;color: red;"}

# Backup Original Firmware

a.k.a: have a backup plan. And yes, I lost my original `Anet A8 Plus` firmware dump 😅
