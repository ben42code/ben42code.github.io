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
{: style="box-shadow: 10px 10px 5px 0 rgba(0, 0, 0, 0.4);"}

# Requirements

To make this process less painful, I do recommend few pieces of equipement to proceed. You can purchase those from your favorite online retailer for a very reasonable price. Those are very common.
- An USBASP programmer
- A 10 (2x5) pin IDC Ribbon Cable
- An 10-pin to 6-pin ICSP adapter

Here are some of my purchases:
<table>
<tbody>
<tr>
<td><div markdown="1">
[![front](/assets/posts/2025-11-28-aneta8-plus-firmware-update/front.jpg){:width="100px" style="box-shadow: 10px 10px 5px 0 rgba(0, 0, 0, 0.4);"}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/front.jpg)
</div></td>
<td><div markdown="1">
[![front](/assets/posts/2025-11-28-aneta8-plus-firmware-update/back.jpg){:width="100px" style="box-shadow: 10px 10px 5px 0 rgba(0, 0, 0, 0.4);"}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/back.jpg)
</div></td>
<td><div markdown="1">
[![front](/assets/posts/2025-11-28-aneta8-plus-firmware-update/cable.jpg){:width="100px" style="box-shadow: 10px 10px 5px 0 rgba(0, 0, 0, 0.4);"}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/cable.jpg)
</div></td>
</tr>
<tr>
<td><div markdown="1">
[![front](/assets/posts/2025-11-28-aneta8-plus-firmware-update/10x6_back.jpg){:width="100px" style="box-shadow: 10px 10px 5px 0 rgba(0, 0, 0, 0.4);"}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/10x6_back.jpg)
</div></td>
<td><div markdown="1">
[![front](/assets/posts/2025-11-28-aneta8-plus-firmware-update/10x6_front.jpg){:width="100px" style="box-shadow: 10px 10px 5px 0 rgba(0, 0, 0, 0.4);"}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/10x6_front.jpg)
</div></td>
<td><div markdown="1">
[![front](/assets/posts/2025-11-28-aneta8-plus-firmware-update/10x6_topbottom.jpg){:width="100px" style="box-shadow: 10px 10px 5px 0 rgba(0, 0, 0, 0.4);"}](/assets/posts/2025-11-28-aneta8-plus-firmware-update/10x6_topbottom.jpg)
</div></td>
</tr>
</tbody>
</table>
{:style="width: fit-content;"}

**Disclaimer**: All the USBASP programmers I purchased came with an outdated firmware. Leading to a well-documented (non-blocking) error message when you try to read/write the `Anet A8 Plus` firmware.
```
warning : Can not Set sck period . usbasp please check for firmware update .
```
**Not blocking** but it might slow down a bit the firmware transfer operation. It can be solved following these steps: [How to Upgrade Firmware in USBasp Programmer](https://www.youtube.com/watch?v=1tU7cAFwzig) from [Zero Amps Electronics Youtube channel](https://www.youtube.com/@zeroampselectronics).
<iframe width="210" height="160" src="http://www.youtube.com/embed/1tU7cAFwzig" frameborder="0" allowfullscreen></iframe>
{: style="box-shadow: 10px 10px 5px 0 rgba(0, 0, 0, 0.4);"}

⚠️ To perform the USBASP programmer firmware update, you'll need another USBASP programmer! Since this device is really cheap, and just in case => do purchase at least 2 of them right away💵📦!

# 
