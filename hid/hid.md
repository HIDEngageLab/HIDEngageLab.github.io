---
layout: default
title: HID
permalink: /hid/hid
---

# USB HID Reports

<h4>Report-Spezifikation</h4>

<a name="hci-revision"></a>**Next Revision: 1.0, WORK IN PROGRESS**  

<h1>Table of content<button class="collapsible" id="bla"/></h1>
<div class="content" id="bladata" markdown="1">
* 
{:toc}
</div>

# Overview

For USB HID protocol please look at [documentation](https://www.usb.org/hid){:target="_blank"} or online.  

For a better understanding of the communication algorithms, please refer to the [HCI description](/hci/hci).

The payload for setting and getting reports will be described below.

The keypad is compatible with any USB HID host. You can control extended functionality either through the HCI or HID interfaces using your code or tools from the VariKey project.

<figure id ="context-svg">
    <img src="{{ "/assets/images/eval-context-hid.svg" | relative_url }}">
    <figcaption>Concept overview.</figcaption>
</figure>

# Anhang

{% include_relative hid-codes.md %}
