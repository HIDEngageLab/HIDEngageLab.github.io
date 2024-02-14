---
layout: default
title: HCI
permalink: /hci/hci
---

# Host Controller Interface, HCI

<h4>Interface aud Protocol Specification</h4>

<a name="hci-revision"></a>
**Next Revision: 1.0, WORK IN PROGRESS**  

<h1>Table of content<button class="collapsible" id="bla"/></h1>
<div class="content" id="bladata" markdown="1">
* 
{:toc}
</div>

<div class="pagebreak"/>

# Overview

The Host Controller Interface (HCI) is a proprietary communication protocol used in the context of interaction between the  embedded devices.

This protocol was designed for machine-to-machine (M2M) communication between a keypad module and an application on a target host.

Using a TTL to USB keypad, the module can be connected to a PC for testing and evaluation purposes (see figure below).

<figure id="context-svg">
    <img src="{{ "/assets/images/eval-context-hci.svg" | relative_url }}">
    <figcaption>Concept overview.</figcaption>
</figure>

The keypad firmware utilizes the UART interface of the microcontroller configured at 115200 bits/second, 8 bits, 1 stop bit, and no handshake.

Please note: the HCI interface exchanges byte sequences, not easily readable text messages. 
These byte sequences can be transmitted using a terminal program. 

To create or interpret the byte sequences, specific documentation and tools (such as Varikey Commander) are required.
If messages are manually composed, a correct checksum is necessary. 
Efficient and accurate results can be achieved using an online CRC calculator [here](https://crccalc.com/).

Serialized numbers are transported in Network Byte Order (Most Significant Bit first). 
The numbering of bytes within a message occurs from left to right.

Important: The <a href="#hci-revision">revision number</a> of the protocol specification should match the implemented functionality of the <a href="#firmware">firmware</a> with the same revision.

<div class="pagebreak"/>

# Frame

Messages within the HCI protocol are exchanged packed in HDLC-like frames (UART PDUs).

Structure of an HDLC frame within the HCI protocol in the following table.

<figure id="frame-structure">
    <table>
        <tr>
            <th class="small_col">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>0x7E</td>
            <td>Start character</td>
        </tr>
        <tr>
            <td>1</td>
            <td>ADDRESS</td>
            <td>Address field; Default for HCI 0x20</td>
        </tr>
        <tr>
            <td>2</td>
            <td>CONTROL</td>
            <td>Reserved; Default for HCI 0x00</td>
        </tr>
        <tr>
            <td>3-N</td>
            <td>PAYLOAD</td>
            <td>HCI-Message in payload (=Frame SDU)</td>
        </tr>
        <tr>
            <td>N+1</td>
            <td>CRC</td>
            <td>CRC-16 checksum MSB</td>
        </tr>
        <tr>
            <td>N+2</td>
            <td>CRC</td>
            <td>CRC-16 checksum LSB</td>
        </tr>
        <tr>
            <td>N+3</td>
            <td>0x7E</td>
            <td>Stop character</td>
        </tr>
    </table>
    <figcaption>Frame structure.</figcaption>
</figure>

Address field is consistently set to `0x20` for communication with the keypad firmware.

In case there are bytes within the payload having the same value as the frame delimiter `0x7E`, these are 'escaped' to a sequence `0x7D 0x5E` (refer to High-Level Data Link Control, HDLC Framing).

Caution: The checksum is also 'escaped' if necessary.

A robust checksum is generated over the payload content, utilizing <span class=nobr>CRC-16/XMODEM</span> constants during calculation. 
Further information about the 16-bit checksum can be found online or in literature.

An effective tool for checksum calculation is available as an online [CRC calculator](https://crccalc.com/). 
Sample implementations in C and Python are also provided.

<div class="pagebreak"/>

# Payload

The Frame Payload transports messages within the HCI Protocol.

These messages consist of a mandatory command code and additional optional fields (s. <a href="#frame-payload">table</a> below).

<figure id="frame-payload">
    <table>
        <tr>
            <th class="small_col">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>COMMAND</td>
            <td>Command code</td>
        </tr>
        <tr>
            <td>M</td>
            <td>CONTENT</td>
            <td>Message fields; A byte array (can also be of length 0)</td>
        </tr>
    </table>
    <figcaption>HCI payload structure.</figcaption>
</figure>

Field `COMMAND` consists of a command code and a primitive code. 
The command code occupies the first 6 bits of the command; the last two bits encode the primitive (service direction) of a message.

<figure id="command-byte">
    <table>
        <tr style="text-align:center">
            <th>7</th>
            <th>6</th>
            <th>5</th>
            <th>4</th>
            <th>3</th>
            <th>2</th>
            <th>1</th>
            <th>0</th>
        </tr>
        <tr>
            <td colspan="6">Command code</td>
            <td colspan="2">Primitive</td>
        </tr>
    </table>
    <figcaption>Structure of the command code (byte COMMAND).</figcaption>
</figure>

In the message exchange between a Host Controller and a Keypad module the Host (e.g., a PC) acts as the Service User and the keypad acts as the Service Provider.

The primitives are often considered in pairs, for instance, from a Request (REQ) with a Confirmation (CFM) or from an Indication (IND) with a Response (RES).

<figure id="primitives">
    <table>
        <tr>
            <th class="small_left">Primitive</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>REQ</td>
            <td>0x00</td>
            <td>Service user (Host) initiates a Request.</td>
        </tr>
        <tr>
            <td>CFM</td>
            <td>0x01</td>
            <td>Service Provider (Keypad) confirms the Host's request.</td>
        </tr>
        <tr>
            <td>IND</td>
            <td>0x02</td>
            <td>Service Provider (Keypad) sends an Indication to the Host.</td>
        </tr>
        <tr>
            <td>RES</td>
            <td>0x03</td>
            <td>Service User (Host) responds with a Response to the Service Provider's (Keypad's) Indication.</td>
        </tr>
    </table>
    <figcaption>Message primitives.</figcaption>
</figure>

Command codes are 6 bits in size and range from `0x00` to `0xFC`.
In total, there are 64 possible commands, each extended with a primitive.

## Command list

The currently specified command codes in the HCI protocol are listed in alphabetical order in the following table.

<figure id="commands">
    <table>
        <tr>
            <th>Command</th>
            <th>Description</th>
        </tr>
        <tr>
            <td id="comment" colspan="3">Control</td>
        </tr>
        <tr>
            <td><a href="#gadget">GADGET</a></td>
            <td>Keypad operation mode</td>
        </tr>
        <tr>
            <td><a href="#crc_hash">HASH</a></td>
            <td>Hash value calculation</td>
        </tr>
        <tr>
            <td><a href="#protocol">PROTOCOL</a></td>
            <td>Protocol engine status</td>
        </tr>
        <tr>
            <td><a href="#reset">RESET</a></td>
            <td>Keypad restart</td>
        </tr>
        <tr>
            <td><a href="#temperature">TEMPERATURE</a></td>
            <td>Temperature sensor data</td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Features</td>
        </tr>
        <tr>
            <td><a href="#backlight">BACKLIGHT</a></td>
            <td>Backlight control</td>
        </tr>
        <tr>
            <td><a href="#display">DISPLAY</a></td>
            <td>Display control</td>
        </tr>
        <tr>
            <td><a href="#gpio">GPIO</a></td>
            <td>GPIO pins control</td>
        </tr>
        <tr>
            <td><a href="#keypad">KEYPAD</a></td>
            <td>Event control</td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Settings</td>
        </tr>
        <tr>
            <td><a href="#identity">IDENTITY</a></td>
            <td>Keypad identity</td>
        </tr>
        <tr>
            <td><a href="#parameter">PARAMETER</a></td>
            <td>Persistent settings</td>
        </tr>
    </table>
    <figcaption>HCI command codes (alphabetical).</figcaption>
</figure>

Additional command codes are currently not used and are reserved for protocol extensions.

<div class="pagebreak"/>

# Scope

The commands are divided into the message fields. 
The size, type and position of a field in a command are strictly defined by the command code.

The contents (codes) of all message fields are only valid in the context of the respective command.
For instance, a `GET` code within a `RESULT` field may be encoded with different values in different commands.

Exceptions are the <a href="#common-result-codes">commonly used</a> result codes. 
The codes for `SUCCESS` (`0x00`), `FAILURE` (`0x01`), `UNKNOWN` (`0x02`), `UNSUPPORTED` (`0x03`), and `ERROR` (`0x04`) are uniformly encoded across all HCI commands.

## Control

These are the gadget control and helper messages.

The helper functions in this section are intended to increase user convenience.

State diagram of the keypad application below shows possible operation modes of the event engine.

<figure id="keypad-states">
        <img src="{{ "/assets/images/keypad-states.svg" | relative_url }}">
    <figcaption>Keypad states.</figcaption>
</figure>

The processing of the buttons and incremental encoder events is only activated on the mounted devices (state `ACTIVE`).

Operation mode can be set by [`GADGET`](#gadget) command.

Unknown commands are responded to with a status indication message [`PROTOCOL`](#protocol). 

The ambient temperature from an internal sensor on the keypad can be read through a [`TEMPERATURE`](#temperature) request.

Calculating the CRC-16 hash values of a payload can be done through a [`HASH`](#crc_hash).

## Gadget features

The core functionalities of the keypad module include:

- Handling button and incremental encoder events and transmitting them to the host via HID reports or HCI messages.
- Controlling a small OLED information display to facilitate smoother interaction with the module.
- Backlight control increasing user experience.
- GPIO functionality with both input and output capabilities, enabling the user control of external peripherals.

### Keypad events

HCI keypad events are indication messages <a href="#keypad">`KEYPAD`</a> that occur asynchronously.
The events can be caused by the state change of the keypad and by the internal logic of the keypad.

Application records key or wheel hardware events every time the buttons are pressed or every time the rotary wheel position changes.
These operating events are exchanged between the keypad module and the host computer.

### Information Display control
{: #scope-display}

The keyboard software can control a small 128x32 pixel OLED display.

The display can show small images and short text messages in four font sizes.

The images and fonts should be known and already converted into a special format (source code structures) before compilation.

Python scripts for editing fonts and converting created artifacts into source code are available in the `pixel2code` project directory.

The available font sizes are are listed in the table below.

<figure id="display-font">
    <table>
        <tr>
            <th class="small_col">Mode</th>
            <th class="small_col">Value</th>
            <th class="small_col">Comment</th>
        </tr>
        <tr>
            <td>SMALL</td>
            <td>0</td>
            <td>Default font.</td>
        </tr>
            <td>NORMAL</td>
            <td>1</td>
            <td></td>
        <tr>
            <td>BIG</td>
            <td>2</td>
            <td></td>
        </tr>
        <tr>
            <td>HUGE</td>
            <td>3</td>
            <td></td>
        </tr>
        <tr>
            <td>SYMBOL</td>
            <td>4</td>
            <td></td>
        </tr>
    </table>
    <figcaption>Text fonts.</figcaption>
</figure>

### Backlight control
{: #scope-backlight}

The keypad controller can control smart LEDs like WS2812.
The RGB color of each smart LED in a sequentially connected chain can be switched separately.

The LEDs are powered before the host boots, giving the user a kind of early feedback.

The keypad firmware functionality <a href="#backlight">`BACKLIGHT`</a> can address two of three intelligent LEDs.
The colors on the left and right can be set manually, the color for the third LED is a calculated average.

The keypad software has some automatic backlight programs.
Available backlight engine modes are in the table below.

<figure id="backlight-mode">
    <table>
        <tr>
            <th class="small_col">Mode</th>
            <th class="small_col">Value</th>
            <th class="small_col">Comment</th>
        </tr>
        <tr>
            <td>ALERT</td>
            <td>0</td>
            <td>Red, flashing quickly.</td>
        </tr>
            <td>CONST</td>
            <td>1</td>
            <td>Las color.</td>
        <tr>
            <td>MEDIUM</td>
            <td>2</td>
            <td>Color morphing along a predefined color chain.</td>
        </tr>
        <tr>
            <td>MORPH</td>
            <td>3</td>
            <td>Morph the last colors left and right into a specific color. Requires a color parameter.</td>
        </tr>
        <tr>
            <td>MOUNT</td>
            <td>4</td>
            <td>Set predefined color value.</td>
        </tr>
        <tr>
            <td>OFF</td>
            <td>5</td>
            <td>Switch backlight off.</td>
        </tr>
        <tr>
            <td>SET</td>
            <td>6</td>
            <td>Set a specific color left and right. Requires a color parameter.</td>
        </tr>
            <td>SLOW</td>
            <td>7</td>
            <td>Slow color morphing along a predefined color chain.</td>
        <tr>
            <td>SUSPEND</td>
            <td>8</td>
            <td>Yellow, slowly flashing.</td>
        </tr>
        <tr>
            <td>TURBO</td>
            <td>9</td>
            <td>Fast color morphing along a predefined color chain.</td>
        </tr>
        <tr>
            <td>UNDEFINED</td>
            <td>255</td>
            <td>0xFF</td>
        </tr>
    </table>
    <figcaption>Backlight mode.</figcaption>
</figure>

The both LEDs can be used as a backlight for the left and right parts of the keypad.
The third can be used as well as backlight for the small information display and the rotary wheel.

### GPIO control
{: #scope-gpio}

The keypad firmware offers 4 GPIO pins.

The pins can be configured as output and switched low and high by an HCI request command <a href="#gpio">`GPIO`</a>.

The pins can be configured as input and inform the host of the level change with an indication.

Attention: Pin status change indication should be used in user communication context (1-20 ms). 
The problem is a very short (but existing) delay and loss of events in a fast change series.

## Settings and Parameter
{: #scope-parameter}

The protocol is capable of returning the hardware revision (set by compilation) and the current software revision.

You can find the software version with the [FIRMWARE](#firmware) request.
The hardware revision can be returned with the [HARDWARE](#hardware) request.
When assigning firmware and hardware revisions, the rules of [Semantic Versioning](https://semver.org/lang/de/) are largely followed.

An [IDENTITY](#identity) request can return a unique keyboard serial number and platform identifier.

The current HCI protocol software release supports the following persistent parameters:

<figure id="parameter-code">
    <table>
        <tr>
            <th class="small_col">Parameter</th>
            <th class="small_col">CODE</th>
            <th class="small_col">Description</th>
        </tr>
        <tr>
            <td><a href="#backlight-parameter">BACKLIGHT</a></td>
            <td>0xA1</td>
            <td>Backlight settings</td>
        </tr>
        <tr>
            <td><a href="#display-parameter">DISPLAY</a></td>
            <td>0xA3</td>
            <td>Information display settings</td>
        </tr>
        <tr>
            <td><a href="#feature-parameter">FEATURES</a></td>
            <td>0x51</td>
            <td>Disableable firmware features</td>
        </tr>
        <tr>
            <td><a href="#keypad-parameter">KEYPAD</a></td>
            <td>0xA2</td>
            <td>Key constants</td>
        </tr>
        <tr>
            <td><a href="#maintainer-parameter">MAINTAINER</a></td>
            <td>0x23</td>
            <td>Maintainer identifier</td>
        </tr>
        <tr>
            <td><a href="#mapping-parameter">MAPPING</a></td>
            <td>0xB0</td>
            <td>Keypad mapping</td>
        </tr>
        <tr>
            <td><a href="#position-parameter">POSITION</a></td>
            <td>0x24</td>
            <td>Geographic coordinates</td>
        </tr>
        <tr>
            <td><a href="#serial_number-parameter">SERIAL_NUMBER</a></td>
            <td>0x11</td>
            <td>Serial number</td>
        </tr>
        <tr>
            <td><a href="#user-parameter">USER</a></td>
            <td>0x70</td>
            <td>Free usable</td>
        </tr>
    </table>
    <figcaption>Parameter codes</figcaption>
</figure>

### BACKLIGHT
{: .cmd-head #backlight-parameter}

The parameter contains four variables: mode at startup, color left and color right at startup and timeout.

The byte structure follows in the following table.

<figure id="backlight-parameter-structure">
    <table>
        <tr>
            <th class="small_col">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>MODE</td>
            <td>Backlight <a href="#backlight-mode">mode</a></td>
        </tr>
        <tr>
            <td>1-4</td>
            <td>LEFT</td>
            <td>Color left four bytes: A,R,G,B</td>
        </tr>
        <tr>
            <td>5-8</td>
            <td>RIGHT</td>
            <td>Color right four bytes: A,R,G,B</td>
        </tr>
        <tr>
            <td>8-9</td>
            <td>TIMEOUT</td>
            <td>Timeout in seconds</td>
        </tr>
    </table>
    <figcaption>Backlight parameter structure.</figcaption>
</figure>

Default values are:

- Mode: TURBO
- Left color: (0,0,15,15)
- Right color: (0,0,14,31)
- Timeout: 15s

### DISPLAY
{: .cmd-head #display-parameter}

A bit field with display engine features.

<figure id="features-parameter-structure">
    <table style="text-align:center">
        <tr>
            <th>7</th>
            <th>6</th>
            <th>5</th>
            <th>4</th>
            <th>3</th>
            <th>2</th>
            <th>1</th>
            <th>0</th>
        </tr>
        <tr>
            <td colspan="1">R</td>
            <td colspan="1">I</td>
            <td colspan="1">S</td>
            <td colspan="5">reserved</td>
        </tr>
        <tr>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
        </tr>
    </table>
    <figcaption>Structure of the display parameter.</figcaption>
</figure>

Fields:

- R: Rotate 180 degree (0 default, 1 rotated)
- I: Inverse (0 white on black, 1 black on white)
- S: Slides on suspend (1 on, 0 off)
- Rest: Reserved for extensions

Default values are:

- Rotation: disabled
- Inversion: disabled
- Slides on suspend: enabled

### FEATURES
{: .cmd-head #feature-parameter}

A bit field with disableable firmware features.

<figure id="features-parameter-structure">
    <table style="text-align:center">
        <tr>
            <th>7</th>
            <th>6</th>
            <th>5</th>
            <th>4</th>
            <th>3</th>
            <th>2</th>
            <th>1</th>
            <th>0</th>
            <th>7</th>
            <th>6</th>
            <th>5</th>
            <th>4</th>
            <th>3</th>
            <th>2</th>
            <th>1</th>
            <th>0</th>
        </tr>
        <tr>
            <td colspan="1">A</td>
            <td colspan="1">D</td>
            <td colspan="1">K</td>
            <td colspan="1">W</td>
            <td colspan="12">reserved</td>
        </tr>
        <tr style="text-align:right">
            <td>1</td>
            <td>1</td>
            <td>1</td>
            <td>1</td>
            <td>1</td>
            <td>1</td>
            <td>1</td>
            <td>1</td>
            <td>1</td>
            <td>1</td>
            <td>1</td>
            <td>1</td>
            <td>1</td>
            <td>1</td>
            <td>1</td>
            <td>1</td>
        </tr>
    </table>
    <figcaption>Structure of the features parameter.</figcaption>
</figure>

Fields (1 enabled, 0 disabled):

- A: Activation on start
- D: Display is enabled 
- K: Keypad is enabled  
- W: Wakeup host on suspend  
- Rest: Reserved for extensions

Default values are all 1 or enabled.

### KEYPAD
{: .cmd-head #keypad-parameter}

Some keypad constants. 

The byte structure follows in the following table.

<figure id="keypad-parameter-structure">
    <table>
        <tr>
            <th class="small_col">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0-1</td>
            <td>CLICK_DURATION</td>
            <td>Button down duration for a click in ms</td>
        </tr>
        <tr>
            <td>2-3</td>
            <td>PUSH_DURATION</td>
            <td>Button down duration for a push in ms</td>
        </tr>
    </table>
    <figcaption>Keypad parameter structure.</figcaption>
</figure>

Default values are:

- CLICK_DURATION: 128ms
- PUSH_DURATION: 384ms

### MAINTAINER
{: .cmd-head #maintainer-parameter}

A maintainer identities for the internal purposes.

<figure id="maintainer-parameter-structure">
    <table style="text-align:center">
        <tr>
            <th>7</th>
            <th>6</th>
            <th>5</th>
            <th>4</th>
            <th>3</th>
            <th>2</th>
            <th>1</th>
            <th>0</th>
            <th>7</th>
            <th>6</th>
            <th>5</th>
            <th>4</th>
            <th>3</th>
            <th>2</th>
            <th>1</th>
            <th>0</th>
        </tr>
        <tr>
            <td colspan="2">P</td>
            <td colspan="4">HW</td>
            <td colspan="12">M</td>
        </tr>
        <tr>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
            <td>0</td>
        </tr>
    </table>
    <figcaption>Parameter maintainer structure.</figcaption>
</figure>

Fields:

- M: Maintainer code
- HW: Hardware revision
- P: Protocol revision

Default values are:

- P: 0
- HW: 0
- M: 0

These values are reserved for the VariKey keypads under development.

Caution: Devices with default values shouldn't be used in the production. 

### MAPPING
{: .cmd-head #mapping-parameter}

A 24-byte array with a key mapping values. 
The first value is corresponds with the KEY_ID 0x00, the second with the KEY_ID 0x01 and vice versa.

The byte structure follows in the following table.

<figure id="user-parameter-structure">
    <table>
        <tr>
            <th style="width:3em">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td id="comment" colspan="3">Section: buttons</td>
        </tr>
        <tr>
            <td>0-9</td>
            <td>CODE</td>
            <td><a href="/hid/hid#hid-codes">HID codes</a> for the internal KEY_01-KEY_09 <a href="#keypad-internal-code">(table)</a></td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Section: selection wheel 1</td>
        </tr>
        <tr>
            <td>10</td>
            <td>CODE</td>
            <td>HID code for KEY_70 UP</td>
        </tr>
        <tr>
            <td>11</td>
            <td>CODE</td>
            <td>HID code for KEY_71 DOWN</td>
        </tr>
        <tr>
            <td>12</td>
            <td>CODE</td>
            <td>HID code for KEY_72 SWITCH</td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Section: selection wheel 2</td>
        </tr>
        <tr>
            <td>13</td>
            <td>CODE</td>
            <td>HID code for KEY_73 UP</td>
        </tr>
        <tr>
            <td>14</td>
            <td>CODE</td>
            <td>HID code for KEY_74 DOWN</td>
        </tr>
        <tr>
            <td>15</td>
            <td>CODE</td>
            <td>HID code for KEY_75 SWITCH</td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Section: selection joystick 1</td>
        </tr>
        <tr>
            <td>16</td>
            <td>CODE</td>
            <td>HID code for KEY_80 DOWN</td>
        </tr>
        <tr>
            <td>17</td>
            <td>CODE</td>
            <td>HID code for KEY_81 LEFT</td>
        </tr>
        <tr>
            <td>18</td>
            <td>CODE</td>
            <td>HID code for KEY_82 RIGHT</td>
        </tr>
        <tr>
            <td>19</td>
            <td>CODE</td>
            <td>HID code for KEY_83 UP</td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Section: selection joystick 2</td>
        </tr>
        <tr>
            <td>20</td>
            <td>CODE</td>
            <td>HID code for KEY_84 DOWN</td>
        </tr>
        <tr>
            <td>21</td>
            <td>CODE</td>
            <td>HID code for KEY_85 LEFT</td>
        </tr>
        <tr>
            <td>22</td>
            <td>CODE</td>
            <td>HID code for KEY_86 RIGHT</td>
        </tr>
        <tr>
            <td>23</td>
            <td>CODE</td>
            <td>HID code for KEY_87 UP</td>
        </tr>
    </table>
    <figcaption>User parameter structure.</figcaption>
</figure>

Default values are twenty four 0xFF.

### POSITION
{: .cmd-head #position-parameter}

The parameter can be used to save the predefined or expected position of a device with the keypad.

The byte structure follows in the following table.

<figure id="serial_number-structure">
    <table>
        <tr>
            <th class="small_col">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0-3</td>
            <td>LATITUDE</td>
            <td>Position latitude</td>
        </tr>
        <tr>
            <td>4-7</td>
            <td>LONGITUDE</td>
            <td>Position longitude</td>
        </tr>
    </table>
    <figcaption>Serial number parameter structure.</figcaption>
</figure>

Two 4-byte serialized float values, each representing a latitude and a longitude.

Default values represent a randomly selected location.

### SERIAL_NUMBER
{: .cmd-head #serial_number-parameter}

A 12-byte field containing a unique serial number.

The byte structure follows in the following table.

<figure id="serial_number-structure">
    <table>
        <tr>
            <th class="small_col">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0-11</td>
            <td>SERIAL_NUMBER</td>
            <td>Unique serial number</td>
        </tr>
    </table>
    <figcaption>Serial number parameter structure.</figcaption>
</figure>

The value is always regenerated if no valid number is stored (first start for example).

The values adhere to the specifications of the pseudo-random number generator library used and follow a normal distribution.

The seed value for the random number generator is derived from the noise of the temperature sensor; this keeps the probability of two keypads receiving the same serial number extremely low.

### USER
{: .cmd-head #user-parameter}

A two-byte array that can be freely used by the maintainer or user.
The value of this parameter is not interpreted by the keypad firmware.

The byte structure follows in the following table.

<figure id="user-parameter-structure">
    <table>
        <tr>
            <th class="small_col">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0-2</td>
            <td>USER</td>
            <td>Free parameter</td>
        </tr>
    </table>
    <figcaption>User parameter structure.</figcaption>
</figure>

Default value is 0xFFFF.

<div class="pagebreak"/>

# Syntax

The command syntax is described in alphabetical order.

The RESULT field code values common to all commands are listed in the following table.

<figure id="common-result-codes">
    <table>
        <tr>
            <th class="small_left">RESULT</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>CUSTOM</td>
            <td>0x80</td>
            <td>Identifier for the first custom result value</td>
        </tr>
        <tr>
            <td>ERROR</td>
            <td>0x04</td>
            <td>Execution error</td>
        </tr>
        <tr>
            <td>FAILURE</td>
            <td>0x01</td>
            <td>Generic Error</td>
        </tr>
        <tr>
            <td>SUCCESS</td>
            <td>0x00</td>
            <td>Success</td>
        </tr>
        <tr>
            <td>UNKNOWN</td>
            <td>0x02</td>
            <td>Invalid/unknown content</td>
        </tr>
        <tr>
            <td>UNSUPPORTED</td>
            <td>0x03</td>
            <td>Is not supported by this firmware</td>
        </tr>
        <tr>
            <td>UNDEFINED</td>
            <td>0xFF</td>
            <td>Undefined result value</td>
        </tr>
    </table>
    <figcaption>Common result codes.</figcaption>
</figure>

All the custom result codes are great or equal `0x80`.

The FUNCTION field code values common to all commands are listed in the following table.

<figure id="common-function-codes">
    <table>
        <tr>
            <th class="small_left">FUNCTION</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>GET</td>
            <td>0x00</td>
            <td>Get a value</td>
        </tr>
        <tr>
            <td>SET</td>
            <td>0x01</td>
            <td>Set a value</td>
        </tr>
        <tr>
            <td>ENABLE</td>
            <td>0x02</td>
            <td>Enable process</td>
        </tr>
        <tr>
            <td>DISABLE</td>
            <td>0x03</td>
            <td>Disable process</td>
        </tr>
        <tr>
            <td>START</td>
            <td>0x05</td>
            <td>Start process</td>
        </tr>
        <tr>
            <td>STOP</td>
            <td>0x06</td>
            <td>Stop process</td>
        </tr>
        <tr>
            <td>UNDEFINED</td>
            <td>0xFF</td>
            <td>Undefined value</td>
        </tr>
    </table>
    <figcaption>Common function codes.</figcaption>
</figure>

All the custom function codes are great or equal `0x80`.

<div class="pagebreak"/>

## GADGET
{: .cmd-head}

Query and set the operation mode of a keypad.

<figure id="gadget-function">
    <table>
        <tr>
            <th class="small_left">FUNCTION</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>GET</td>
            <td>0x00</td>
            <td>Query operation mode</td>
        </tr>
        <tr>
            <td>MOUNT</td>
            <td>0x65</td>
            <td>Mount keypad device</td>
        </tr>
        <tr>
            <td>RESET</td>
            <td>0x69</td>
            <td>Restart keypad</td>
        </tr>
        <tr>
            <td>RESUME</td>
            <td>0x68</td>
            <td>Return from suspend state</td>
        </tr>
        <tr>
            <td>SUSPEND</td>
            <td>0x67</td>
            <td>Start suspend state</td>
        </tr>
        <tr>
            <td>UNMOUNT</td>
            <td>0x66</td>
            <td>Release keypad device</td>
        </tr>
    </table>
    <figcaption>Function codes.</figcaption>
</figure>

Command uses the <a href="#common-result-codes">common result codes</a>.

Extended result codes for the `RESULT` field are provided in the table below.

<figure id="gadget-results">
    <table>
        <tr>
            <th class="small_left">RESULT</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>WRONG_STATE</td>
            <td>0x80</td>
            <td>State switch is not possible.</td>
        </tr>
    </table>
    <figcaption>Status result codes.</figcaption>
</figure>

Sequence diagram illustrates change of the keypad state from `IDLE` to `ACTIVE` operation mode.

<figure id="keypad-states">
        <img src="{{ "/assets/images/keypad-states-undefined.svg" | relative_url }}">
    <figcaption>Keypad state change from IDLE to ACTIVE.</figcaption>
</figure>

Changing the keypad state in other states has a similar process.

### GADGET+REQ 0x08
{: .cmd}

Inquiry about the operation and mode of the keypad.

<figure id="gadget-req">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>GADGET+REQ</td>
            <td>0x08 Command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>FUNCTION</td>
            <td>Code <a href="#gadget-function">Table</a></td>
        </tr>
    </table>
    <figcaption>GADGET+REQ payload structure.</figcaption>
</figure>

Example:

<samp>7E 20 01<mark>08</mark>81 08 7E</samp>

### GADGET+CFM 0x09
{: .cmd}

A confirmation of a status request.

<figure id="gadget-cfm">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>GADGET+CFM</td>
            <td>0x09 Command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>RESULT</td>
            <td>Code <a href="#gadget-results">Table</a></td>
        </tr>
        <tr>
            <td>2</td>
            <td>FUNCTION</td>
            <td>Code <a href="#gadget-function">Table</a></td>
        </tr>
        <tr>
            <td>3</td>
            <td>STATE</td>
            <td>Code <a href="#control">Table</a></td>
        </tr>
        <tr>
            <td>4-7</td>
            <td>UNIQUE_ID</td>
            <td>Last 5 bytes of the serial number</td>
        </tr>
    </table>
    <figcaption>GADGET+CFM payload structure.</figcaption>
</figure>

Example of a response to a status request from a keypad with a `UNIQUE_ID` equal to <samp>B4250481</samp>:

<samp>7E 20 01<mark>09 00 00 00 CB 0B 3D 4D</mark>F9 D3 7E</samp>

### GADGET+IND 0x0A
{: .cmd}

A status message informs the host about the current status of a keypad.
This message appears after every restart and after every change in status, as soon as the change in status has been completed.

<figure id="gadget-ind">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>GADGET+IND</td>
            <td>0x0A Command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>FUNCTION</td>
            <td>Code <a href="#gadget-function">Table</a></td>
        </tr>
        <tr>
            <td>2</td>
            <td>STATE</td>
            <td>State <a href="#control">chart</a></td>
        </tr>
    </table>
    <figcaption>GADGET+IND Payload structure.</figcaption>
</figure>

Example:

<samp>7E 20 01<mark>0A 00 00</mark>F3 4E 7E</samp>

<div class="pagebreak"/>

## HASH
{: .cmd-head}

Calculate hash value of a payload.

Command uses the <a href="#common-result-codes">common result codes</a> only.

### HASH+REQ 0x1C
{: .cmd}

A request for a CRC-16 hash key for the entire payload.
The payload can have a variable length.

<figure id="hash-req">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>HASH+REQ</td>
            <td>0x1C Command code</td>
        </tr>
        <tr>
            <td>1-N</td>
            <td>VALUE</td>
            <td>Byte array with data for hash calculation</td>
        </tr>
    </table>
    <figcaption>HASH+REQ payload structure.</figcaption>
</figure>

Example of a key request for the text line “bla”:

<samp id="hash-req-example">7E 20 01<mark>1C 62 6C 61</mark>93 5E 7E</samp>
<button class="copyable" onclick="CopyExample(this)"/>

### HASH+CFM 0x1D
{: .cmd}

Confirmation of a request for a hash key.

<figure id="key-cfm">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>HASH+CFM</td>
            <td>0x1D Command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>RESULT</td>
            <td>Code <a href="#key-results">Table</a></td>
        </tr>
        <tr>
            <td>2-5</td>
            <td>VALUE</td>
            <td>Serialized 32-bit value, LE</td>
        </tr>
    </table>
    <figcaption>HASH+CFM payload structure.</figcaption>
</figure>

Example of a key confirmation with the key for the text line “bla”:

<samp id="hash-cfm-example">7E 20 01<mark>1D 00 17 42 6E 26</mark>01 01 7E</samp>

<div class="pagebreak"/>

## PROTOCOL
{: .cmd-head}

The HCI engine replies with this message for syntax violations and unknown commands.

### PROTOCOL+IND 0x02
{: .cmd}

Status messages from the HCI Protocol Engine.

Command uses the <a href="#common-result-codes">common result codes</a> only.

<figure id="protocol-ind">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>PROTOCOL+IND</td>
            <td>0x02 Command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>RESULT</td>
            <td>Statuscode <a href="#common-result-codes">Table</a></td>
        </tr>
        <tr>
            <td>2-N</td>
            <td>VALUE</td>
            <td>Frame SDU</td>
        </tr>
    </table>
    <figcaption>PROTOCOL+IND payload structure.</figcaption>
</figure>

Field `VALUE` (Frame-SDU) can contain an erroneous message. 
Caution: The length of the message is variable.

<div class="pagebreak"/>

## RESET
{: .cmd-head}

Restart the keypad with or without registry formatting.

<figure id="reset-functions">
    <table>
        <tr>
            <th class="small_left">FUNCTION</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>SHUTDOWN</td>
            <td>0x80</td>
            <td>Restart</td>
        </tr>
        <tr>
            <td>FORMAT</td>
            <td>0x81</td>
            <td>Format registry and restart</td>
        </tr>
    </table>
    <figcaption>Function codes.</figcaption>
</figure>

Command uses the <a href="#common-result-codes">common result codes</a>.

Extended result codes for the `RESULT` field are provided in the table below.

<figure id="reset-results">
    <table>
        <tr>
            <th class="small_left">RESULT</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>CRITICAL_ERROR</td>
            <td>0x04</td>
            <td>Initialization not possible. Returned if the HW could not be initialized and is in a safe state.</td>
        </tr>
        <tr>
            <td>BACKUP_CREATED</td>
            <td>0x80</td>
            <td>Parameter backup created. Signals that the registry backup is corrupt or not found.</td>
        </tr>
        <tr>
            <td>PARAMETER_MISSED</td>
            <td>0x81</td>
            <td>Parameter registry invalid</td>
        </tr>
        <tr>
            <td>PARAMETER_RECREATED</td>
            <td>0x82</td>
            <td>Parameter registry recreated. Occurs when no backup parameters were found and the registry was rebuilt with default values.</td>
        </tr>
        <tr>
            <td>PARAMETER_RESTORED</td>
            <td>0x83</td>
            <td>Parameter registry restored. Comes when the parameter registry has been (re)created and parameters have been restored from backup.</td>
        </tr>
        <tr>
            <td>WATCHDOG</td>
            <td>0x84</td>
            <td>Reboot after watchdog</td>
        </tr>
    </table>
    <figcaption>Reset result codes.</figcaption>
</figure>

### RESET+REQ 0x04
{: .cmd}

Keypad restart.

<figure id="reset-req">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>RESET+REQ</td>
            <td>0x04 Reset command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>FUNCTION</td>
            <td>Code <a href="#reset-functions">Table</a> (SHUTDOWN, FORMAT)</td>
        </tr>
    </table>
    <figcaption>RESET+REQ payload structure.</figcaption>
</figure>

Reset keypad example:

<samp id="reset-keypad-example">7E 20 01<mark>04 00</mark>CC C4 7E</samp>
<button class="copyable" onclick="CopyExample(this)"/>

### RESET+IND 0x06
{: .cmd}

Message after restarting the keypad.

<figure id="reset-ind">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>RESET+IND</td>
            <td>0x06 Reset indication command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>RESULT</td>
            <td>Code <a href="#reset-results">Table</a></td>
        </tr>
    </table>
    <figcaption>RESET+IND payload structure.</figcaption>
</figure>

Example:

<samp>7E 20 01<mark>06 00</mark>AA A6 7E</samp>

## TEMPERATURE
{: .cmd-head}

Read and transmit the ambient temperature from the internal keypad sensor.

The temperature commands uses the common result codes.

The function codes for a temperature message are provided in the table below.

<figure id="temperature-functions">
    <table>
        <tr>
            <th class="small_left">FUNCTION</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>GET</td>
            <td>0x00</td>
            <td>Request for the value of a parameter</td>
        </tr>
        <tr>
            <td>ALARM</td>
            <td>0x80</td>
            <td>Set new value and save</td>
        </tr>
    </table>
    <figcaption>Function codes.</figcaption>
</figure>

### TEMPERATURE+REQ 0x34
{: .cmd}

Request for a temperature value.

<figure id="temperature-req">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>TEMPERATURE+REQ</td>
            <td>0x34 Command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>FUNCTION</td>
            <td>Code <a href="#temperature-functions">Table</a></td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option ALARM function only</td>
        </tr>
        <tr>
            <td>1</td>
            <td>VALUE</td>
            <td>Float value</td>
        </tr>
    </table>
    <figcaption>TEMPERATURE+REQ payload structure.</figcaption>
</figure>

Example for `GET` function:

<samp>7E 20 01<mark>34 00</mark>76 D7 7E</samp>

### TEMPERATURE+CFM 0x35
{: .cmd}

Temperature value confirmation.

Command uses the <a href="#common-result-codes">common result codes</a> only.

<figure id="temperature-cfm">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>TEMPERATURE+CFM</td>
            <td>0x35 Command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>RESULT</td>
            <td>Code <a href="#common-result-codes">Table</a></td>
        </tr>
        <tr>
            <td>2</td>
            <td>FUNCTION</td>
            <td>Code <a href="#temperature-functions">Table</a></td>
        </tr>
        <tr>
            <td>3-6</td>
            <td>VALUE</td>
            <td>Serialized float value</td>
        </tr>
    </table>
    <figcaption>TEMPERATURE+CFM payload structure.</figcaption>
</figure>

Example:

<samp>7E 20 01<mark>35 00 00 21 AD A4 41</mark>5B E5 7E</samp>

### TEMPERATURE+IND 0x36
{: .cmd}

Temperature value indication.

Command uses the <a href="#common-result-codes">common result codes</a> only.

<figure id="temperature-ind">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>TEMPERATURE+IND</td>
            <td>0x36 Command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>RESULT</td>
            <td>Code <a href="#common-result-codes">Table</a></td>
        </tr>
        <tr>
            <td>2</td>
            <td>FUNCTION</td>
            <td>Code <a href="#temperature-functions">Table</a></td>
        </tr>
        <tr>
            <td>3-6</td>
            <td>VALUE</td>
            <td>Serialized float value</td>
        </tr>
    </table>
    <figcaption>TEMPERATURE+IND payload structure.</figcaption>
</figure>

Example:

<samp>7E 20 01<mark>36 00 00 21 AD A4 41</mark>5B E5 7E</samp>

## BACKLIGHT
{: .cmd-head}

Control the keypad [backlight](#scope-backlight) engine.

This command uses the <a href="#common-result-codes">common result codes</a> and the <a href="#common-function-codes">common function codes</a>.

Custom command result codes are shown in the table below.

<figure id="backlight-result-code">
    <table>
        <tr>
            <th class="small_left">RESULT</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>WRONG_MODE</td>
            <td>0x80</td>
            <td>Unknown backlight mode.</td>
        </tr>
    </table>
    <figcaption>BACKLIGHT custom result codes.</figcaption>
</figure>

The backlight modes can be found in the subchapter scope/backlight in [mode table](#backlight-mode).

### BACKLIGHT+REQ 0x38
{: .cmd}

Backlight request command.

<figure id="backlight-req">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>BACKLIGHT+REQ</td>
            <td>0x38 command code</td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: set PROGRAM</td>
        </tr>
        <tr>
            <td>1</td>
            <td>PROGRAM</td>
            <td>One of values in the <a href="#backlight-mode">mode table</a></td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: SET and MORPH color</td>
        </tr>
        <tr>
            <td>1</td>
            <td>PROGRAM</td>
            <td>One of values in the <a href="#backlight-mode">mode table</a></td>
        </tr>
        <tr>
            <td>2-4</td>
            <td>COLOR_LEFT</td>
            <td>Color value R,G,B for the left LED</td>
        </tr>
        <tr>
            <td>5-7</td>
            <td>COLOR_RIGHT</td>
            <td>Color value R,G,B for the right LED</td>
        </tr>
    </table>
    <figcaption>BACKLIGHT+REQ payload structure.</figcaption>
</figure>

Default behavior for wrong backlight mode is switch in predefined mode on keypad start (TURBO mode). 

Set turbo mode example:

<samp id="turbo-mode-example">7E 20 01<mark>38 09</mark>00 00 7E</samp>
<button class="copyable" onclick="CopyExample(this)"/>

Set red color example:

<samp id="set-color-example">7E 20 01<mark>38 06 FF 00 00 00 0F 0F</mark>00 00 7E</samp>
<button class="copyable" onclick="CopyExample(this)"/>

### BACKLIGHT+CFM 0x39
{: .cmd}

<figure id="backlight-cfm">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>BACKLIGHT+CFM</td>
            <td>0x39 command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>RESULT</td>
            <td>Execution result</td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: set PROGRAM</td>
        </tr>
        <tr>
            <td>2</td>
            <td>PROGRAM</td>
            <td>One of values in the <a href="#backlight-mode">mode table</a></td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: SET and MORPH modes</td>
        </tr>
        <tr>
            <td>2</td>
            <td>PROGRAM</td>
            <td>One of values in the <a href="#backlight-mode">mode table</a></td>
        </tr>
        <tr>
            <td>3-5</td>
            <td>COLOR_LEFT</td>
            <td>Color value R,G,B for the left channel</td>
        </tr>
        <tr>
            <td>6-8</td>
            <td>COLOR_RIGHT</td>
            <td>Color value R,G,B for the right channel</td>
        </tr>
    </table>
    <figcaption>BACKLIGHT+CFM payload structure.</figcaption>
</figure>

Successfully set turbo mode confirmation example:

<samp id="turbo-mode-cfm-example">7E 20 01<mark>39 00 09</mark>00 00 7E</samp>

Successfully confirmation example for set reg color left and blue color right:

<samp id="color-cfm-example">7E 20 01<mark>39 00 06 FF 00 00 00 00 FF</mark>00 00 7E</samp>

## DISPLAY
{: .cmd-head}

Control the keypad [information display](#scope-display) engine.

This command uses the <a href="#common-result-codes">common result codes</a>.

Custom command result codes are shown in the table below.

<figure id="display-function-code">
    <table>
        <tr>
            <th class="small_left">RESULT</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>UNDEFINED_FONT</td>
            <td>0x80</td>
            <td>Unknown font index.</td>
        </tr>
        <tr>
            <td>UNDEFINED_ICON</td>
            <td>0x81</td>
            <td>Unknown icon index.</td>
        </tr>
        <tr>
            <td>WRONG_POSITION</td>
            <td>0x82</td>
            <td>Wrong cursor position.</td>
        </tr>
    </table>
    <figcaption>DISPLAY custom result codes.</figcaption>
</figure>

Custom command function codes are shown in the table below.

<figure id="display-function-code">
    <table>
        <tr>
            <th class="small_left">RESULT</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>CLEAN</td>
            <td>0x35</td>
            <td>Clean up display.</td>
        </tr>
        <tr>
            <td>FONT</td>
            <td>0x31</td>
            <td>Select text font by index.</td>
        </tr>
        <tr>
            <td>ICON</td>
            <td>0x32</td>
            <td>Select icon by index.</td>
        </tr>
        <tr>
            <td>POSITION</td>
            <td>0x33</td>
            <td>Set cursor position.</td>
        </tr>
        <tr>
            <td>TEXT</td>
            <td>0x34</td>
            <td>Print text message.</td>
        </tr>
    </table>
    <figcaption>DISPLAY function codes.</figcaption>
</figure>

### DISPLAY+REQ 0x20
{: .cmd}

Display engine request command.

Attention: The command options vary in size.

<figure id="display-req">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>DISPLAY+REQ</td>
            <td>0x20 command code</td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: CLEAN</td>
        </tr>
        <tr>
            <td>1</td>
            <td>FUNCTION</td>
            <td>0x35 CLEAN</td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: FONT</td>
        </tr>
        <tr>
            <td>1</td>
            <td>FUNCTION</td>
            <td>0x31 FONT</td>
        </tr>
        <tr>
            <td>2</td>
            <td>FONT_INDEX</td>
            <td><a href="#display-font">Font table</a></td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: ICON</td>
        </tr>
        <tr>
            <td>1</td>
            <td>FUNCTION</td>
            <td>0x32 ICON</td>
        </tr>
        <tr>
            <td>2</td>
            <td>ICON_INDEX</td>
            <td>Icon index in the list.</td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: POSITION</td>
        </tr>
        <tr>
            <td>1</td>
            <td>FUNCTION</td>
            <td>0x33 POSITION</td>
        </tr>
        <tr>
            <td>2</td>
            <td>LINE</td>
            <td>Display line 0-3 (pixel row 0, 8, 16 and 24)</td>
        </tr>
        <tr>
            <td>3</td>
            <td>COLUMN</td>
            <td>Display column 0-127</td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: TEXT</td>
        </tr>
        <tr>
            <td>1</td>
            <td>FUNCTION</td>
            <td>0x34 TEXT</td>
        </tr>
        <tr>
            <td>2-21</td>
            <td>TEXT</td>
            <td>Message content max. 19 bytes.</td>
        </tr>
    </table>
    <figcaption>DISPLAY+REQ payload structure.</figcaption>
</figure>

Set small font example:

<samp id="small-font-example">7E 20 01<mark>20 00 00</mark>00 00 7E</samp>
<button class="copyable" onclick="CopyExample(this)"/>

Set position (1, 10) example:

<samp id="position-example">7E 20 01<mark>20 01 01 10</mark>00 00 7E</samp>
<button class="copyable" onclick="CopyExample(this)"/>

Draw logo icon example:

<samp id="draw-logo-example">7E 20 01<mark>20 03 00</mark>00 00 7E</samp>
<button class="copyable" onclick="CopyExample(this)"/>

Print text "AAA" example:

<samp id="print-text-example">7E 20 01<mark>20 02 65 65 65</mark>00 00 7E</samp>
<button class="copyable" onclick="CopyExample(this)"/>

### DISPLAY+CFM 0x21
{: .cmd}

<figure id="backlight-cfm">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>DISPLAY+CFM</td>
            <td>0x21 command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>RESULT</td>
            <td>Execution result</td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: CLEAN</td>
        </tr>
        <tr>
            <td>2</td>
            <td>FUNCTION</td>
            <td>Executed function</td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: FONT</td>
        </tr>
        <tr>
            <td>2</td>
            <td>FUNCTION</td>
            <td>0x00 Font</td>
        </tr>
        <tr>
            <td>3</td>
            <td>FONT_INDEX</td>
            <td><a href="#display-font">Font table</a></td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: ICON</td>
        </tr>
        <tr>
            <td>2</td>
            <td>FUNCTION</td>
            <td>0x03 icon</td>
        </tr>
        <tr>
            <td>3</td>
            <td>ICON_INDEX</td>
            <td>Icon index</td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: POSITION</td>
        </tr>
        <tr>
            <td>2</td>
            <td>FUNCTION</td>
            <td>0x01 POSITION</td>
        </tr>
        <tr>
            <td>3</td>
            <td>LINE</td>
            <td>Display line 0-3 (pixel row 0, 8, 16 and 24)</td>
        </tr>
        <tr>
            <td>4</td>
            <td>COLUMN</td>
            <td>Display column 0-127</td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: TEXT</td>
        </tr>
        <tr>
            <td>2</td>
            <td>FUNCTION</td>
            <td>0x02 TEXT</td>
        </tr>
        <tr>
            <td>3</td>
            <td>TEXT_LENGTH</td>
            <td>Message content length.</td>
        </tr>
    </table>
    <figcaption>DISPLAY+CFM payload structure.</figcaption>
</figure>

Successful set font confirmation example:

<samp id="set-font-cfm-example">7E 20 01<mark>21 00 01</mark>00 00 7E</samp>

## GPIO
{: .cmd-head}

Control GPIO pins on the keypad module.

Extended GPIO command result codes are shown in the table below.

<figure id="gpio-result-code">
    <table>
        <tr>
            <th class="small_left">RESULT</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>UNKNOWN_IDENIFIER</td>
            <td>0x80</td>
            <td>Enable events</td>
        </tr>
        <tr>
            <td>WRONG_DIRECTION</td>
            <td>0x81</td>
            <td>Action is not possible with the actual settings</td>
        </tr>
    </table>
    <figcaption>GPIO command result codes.</figcaption>
</figure>

GPIO command functions codes are shown in the table below.

<figure id="gpio-function-code">
    <table>
        <tr>
            <th class="small_left">FUNCTION</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>DISABLE</td>
            <td>0x03</td>
            <td>Disable events</td>
        </tr>
        <tr>
            <td>ENABLE</td>
            <td>0x02</td>
            <td>Enable events</td>
        </tr>
        <tr>
            <td>DIRECTION_GET</td>
            <td>0x80</td>
            <td>Get direction</td>
        </tr>
        <tr>
            <td>DIRECTION_SET</td>
            <td>0x81</td>
            <td>Set direction</td>
        </tr>
        <tr>
            <td>LEVEL_GET</td>
            <td>0x84</td>
            <td>Get pin state</td>
        </tr>
        <tr>
            <td>LEVEL_SET</td>
            <td>0x85</td>
            <td>Set pin state</td>
        </tr>
    </table>
    <figcaption>GPIO function codes.</figcaption>
</figure>

GPIO command pin identifier codes are shown in the table below.

<figure id="gpio-pin-code">
    <table>
        <tr>
            <th class="small_left">IDENTIFIER</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>PIN1</td>
            <td>0x8A</td>
            <td>PIN 1</td>
        </tr>
        <tr>
            <td>PIN2</td>
            <td>0x8B</td>
            <td>PIN 2</td>
        </tr>
        <tr>
            <td>PIN3</td>
            <td>0x8C</td>
            <td>PIN 3</td>
        </tr>
        <tr>
            <td>PIN4</td>
            <td>0x8D</td>
            <td>PIN 4</td>
        </tr>
    </table>
    <figcaption>GPIO identifier codes.</figcaption>
</figure>

GPIO command direction codes are shown in the table below.

<figure id="gpio-direction-code">
    <table>
        <tr>
            <th class="small_left">DIRECTION</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>INPUT</td>
            <td>0x00</td>
            <td>Input direction</td>
        </tr>
        <tr>
            <td>OUTPUT</td>
            <td>0x01</td>
            <td>Output direction</td>
        </tr>
        <tr>
            <td>UNDEFINED</td>
            <td>0xFF</td>
            <td>undefined behavior</td>
        </tr>
    </table>
    <figcaption>Direction identifier codes.</figcaption>
</figure>

GPIO command pin level codes are shown in the table below.

<figure id="gpio-level-code">
    <table>
        <tr>
            <th class="small_left">DIRECTION</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>LOW</td>
            <td>0x00</td>
            <td>Logical low</td>
        </tr>
        <tr>
            <td>HIGH</td>
            <td>0x01</td>
            <td>Logical high</td>
        </tr>
        <tr>
            <td>UNDEFINED</td>
            <td>0xFF</td>
            <td>Undefined value</td>
        </tr>
    </table>
    <figcaption>Logic level codes.</figcaption>
</figure>

### GPIO+REQ 0x44
{: .cmd}

<figure id="gpio-req">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>GPIO+REQ</td>
            <td>0x44 Command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>IDENTIFIER</td>
            <td>PIN <a href="#gpio-function-code">identifier table</a></td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: disable events, get level or direction</td>
        </tr>
        <tr>
            <td>2</td>
            <td>FUNCTION</td>
            <td>0x02 ENABLE, 0x03 DISABLE, 0x85 LEVEL_GET, 0x81 DIRECTION_GET;<a href="#gpio-function-code">(table)</a></td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: set level</td>
        </tr>
        <tr>
            <td>2</td>
            <td>FUNCTION</td>
            <td>0x84 LEVEL_SET; <a href="#gpio-function-code">(table)</a></td>
        </tr>
        <tr>
            <td>3</td>
            <td>LEVEL</td>
            <td>Logical Level <a href="#gpio-level-code">code table</a></td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: set direction</td>
        </tr>
        <tr>
            <td>2</td>
            <td>FUNCTION</td>
            <td>0x80 DIRECTION_SET; <a href="#gpio-function-code">(full table)</a></td>
        </tr>
        <tr>
            <td>3</td>
            <td>DIRECTION</td>
            <td>Direction <a href="#gpio-direction-code">code table</a></td>
        </tr>
    </table>
    <figcaption>GPIO+REQ payload structure.</figcaption>
</figure>

Example for an ENABLE event for high LEVEL:

<samp id="gpio-enable-example">7E 20 01<mark>44 8A 02 01</mark>00 00 7E</samp>
<button class="copyable" onclick="CopyExample(this)"/>

### GPIO+CFM 0x45
{: .cmd}

Command uses the <a href="#common-result-codes">common result codes</a> only.

<figure id="gpio-cfm">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>GPIO+CFM</td>
            <td>0x45</td>
        </tr>
        <tr>
            <td>1</td>
            <td>RESULT</td>
            <td>Code <a href="#common-result-codes">Table</a></td>
        </tr>
        <tr>
            <td>2</td>
            <td>IDENTIFIER</td>
            <td>PIN <a href="#gpio-function-code">identifier table</a></td>
        </tr>
        <tr>
            <td>3</td>
            <td>FUNCTION</td>
            <td>Function <a href="#gpio-function-code">code table</a></td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: set/get level or enable event</td>
        </tr>
        <tr>
            <td>4</td>
            <td>LEVEL</td>
            <td>Logical Level <a href="#gpio-level-code">code table</a></td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: set/get direction</td>
        </tr>
        <tr>
            <td>4</td>
            <td>DIRECTION</td>
            <td>Direction <a href="#gpio-direction-code">code table</a></td>
        </tr>
    </table>
    <figcaption>GPIO+CFM payload structure.</figcaption>
</figure>

Example:

<samp>7E 20 01<mark>45 00 8A 02</mark>00 00 7E</samp>

### GPIO+IND 0x46
{: .cmd}

Pin logical level change event.

<figure id="gpio-ind">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>GPIO+IND</td>
            <td>0x46</td>
        </tr>
        <tr>
            <td>1</td>
            <td>IDENTIFIER</td>
            <td>PIN <a href="#gpio-function-code">identifier table</a></td>
        </tr>
        <tr>
            <td>4</td>
            <td>LEVEL</td>
            <td>Logical Level <a href="#gpio-level-code">code table</a></td>
        </tr>
    </table>
    <figcaption>GPIO+CFM payload structure.</figcaption>
</figure>

Example:

<samp>7E 20 01<mark>45 00 8A 00</mark>00 00 7E</samp>

## KEYPAD
{: .cmd-head}

Processing user input is a core functionality of the keypad.

Event indications are caused by user interaction with buttons, wheels and joysticks.
The indications can be activated and deactivated with an HCI command.

It is possible to send event requests back to the keypad to simulate user interaction.
All event requests are confirmed with a confirmation.

Events triggered by a request also lead to an indication message on the HCI interface and a corresponding HID report.

Commands use the <a href="#common-result-codes">common result codes</a>.
Custom command result codes are shown in the following table.

<figure id="keypad-result-code">
    <table>
        <tr>
            <th class="small_left">RESULT</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>WRONG_FUNCTION</td>
            <td>0x81</td>
            <td></td>
        </tr>
        <tr>
            <td>WRONG_IDENTIFIER</td>
            <td>0x80</td>
            <td></td>
        </tr>
        <tr>
            <td>WRONG_SOURCE</td>
            <td>0x83</td>
            <td></td>
        </tr>
        <tr>
            <td>WRONG_VALUE</td>
            <td>0x82</td>
            <td></td>
        </tr>
    </table>
    <figcaption>KEYPAD result codes.</figcaption>
</figure>

Keypad command identifier code.

<figure id="keypad-identifier">
    <table>
        <tr>
            <th class="small_left">IDENTIFIER</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>HCI</td>
            <td>0x72</td>
            <td>HCI protocol</td>
        </tr>
        <tr>
            <td>HID</td>
            <td>0x73</td>
            <td>HID protocol</td>
        </tr>
        <tr>
            <td>KEYCODE</td>
            <td>0x74</td>
            <td>Keycode (backdoor) event</td>
        </tr>
        <tr>
            <td>MAPPING</td>
            <td>0x71</td>
            <td>Keypad mapping engine</td>
        </tr>
    </table>
    <figcaption>Keypad command identifier.</figcaption>
</figure>

Keypad event source identifier.

<figure id="keypad-control">
    <table>
        <tr>
            <th class="small_left">CONTROL</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>BUTTON</td>
            <td>0x00</td>
            <td>Button event</td>
        </tr>
        <tr>
            <td>JOYSTICK</td>
            <td>0x02</td>
            <td>Joystick event</td>
        </tr>
        <tr>
            <td>KEYPAD</td>
            <td>0x03</td>
            <td>Keypad operation</td>
        </tr>
        <tr>
            <td>WHEEL</td>
            <td>0x01</td>
            <td>Wheel event</td>
        </tr>
    </table>
    <figcaption>Keypad control entities codes.</figcaption>
</figure>

Keypad command function codes are shown in the table below.

<figure id="keypad-function">
    <table>
        <tr>
            <th class="small_left">FUNCTION</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>DISABLE</td>
            <td>0x03</td>
            <td></td>
        </tr>
        <tr>
            <td>ENABLE</td>
            <td>0x02</td>
            <td></td>
        </tr>
        <tr>
            <td>GET</td>
            <td>0x00</td>
            <td></td>
        </tr>
        <tr>
            <td>SET</td>
            <td>0x01</td>
            <td></td>
        </tr>
    </table>
    <figcaption>KEYPAD command function codes.</figcaption>
</figure>

Table with the internal key code values.

<figure id="keypad-internal-code">
    <table>
        <tr>
            <th class="small_col" rowspan="2">KEY_ID</th>
            <th class="small_col" rowspan="2">CODE</th>
            <th colspan="2">Matrix</th>
            <th rowspan="2">Description</th>
        </tr>
        <tr>
            <th class="small_col">Row</th>
            <th class="small_col">Col</th>
        </tr>
        <tr>
            <td id="comment" colspan="5">Keypad buttons</td>
        </tr>
        <tr>
            <td>KEY_01</td>
            <td>0x00</td>
            <td>0</td>
            <td>0</td>
            <td>Key 1</td>
        </tr>
        <tr>
            <td>KEY_01</td>
            <td>0x00</td>
            <td>0</td>
            <td>GND</td>
            <td>Key 1</td>
        </tr>
        <tr>
            <td>KEY_02</td>
            <td>0x01</td>
            <td>1</td>
            <td>0</td>
            <td>Key 2</td>
        </tr>
        <tr>
            <td>KEY_02</td>
            <td>0x01</td>
            <td>1</td>
            <td>GND</td>
            <td>Key 2</td>
        </tr>
        <tr>
            <td>KEY_03</td>
            <td>0x02</td>
            <td>2</td>
            <td>0</td>
            <td>Key 3</td>
        </tr>
        <tr>
            <td>KEY_03</td>
            <td>0x02</td>
            <td>2</td>
            <td>GND</td>
            <td>Key 3</td>
        </tr>
        <tr>
            <td>KEY_04</td>
            <td>0x03</td>
            <td>3</td>
            <td>0</td>
            <td>Key 4</td>
        </tr>
        <tr>
            <td>KEY_04</td>
            <td>0x03</td>
            <td>3</td>
            <td>GND</td>
            <td>Key 4</td>
        </tr>
        <tr>
            <td>KEY_05</td>
            <td>0x04</td>
            <td>4</td>
            <td>0</td>
            <td>Key 5</td>
        </tr>
        <tr>
            <td>KEY_05</td>
            <td>0x04</td>
            <td>4</td>
            <td>GND</td>
            <td>Key 5</td>
        </tr>
        <tr>
            <td>KEY_06</td>
            <td>0x05</td>
            <td>0</td>
            <td>1</td>
            <td>Softkey 1</td>
        </tr>
        <tr>
            <td>KEY_07</td>
            <td>0x06</td>
            <td>1</td>
            <td>1</td>
            <td>Softkey 2</td>
        </tr>
        <tr>
            <td>KEY_08</td>
            <td>0x07</td>
            <td>2</td>
            <td>1</td>
            <td>Softkey 3</td>
        </tr>
        <tr>
            <td>KEY_09</td>
            <td>0x08</td>
            <td>3</td>
            <td>1</td>
            <td>Softkey 4</td>
        </tr>
        <tr>
            <td>KEY_10</td>
            <td>0x09</td>
            <td>4</td>
            <td>1</td>
            <td>Softkey 5</td>
        </tr>
        <tr>
            <td id="comment" colspan="5">Selector wheels</td>
        </tr>
        <tr>
            <td>KEY_70</td>
            <td>0x0A</td>
            <td></td>
            <td>GPIO10 (C3)</td>
            <td>Wheel 1 UP</td>
        </tr>
        <tr>
            <td>KEY_71</td>
            <td>0x0B</td>
            <td></td>
            <td>GPIO11 (C4)</td>
            <td>Wheel 1 DOWN</td>
        </tr>
        <tr>
            <td>KEY_72</td>
            <td>0x0C</td>
            <td></td>
            <td>GPIO9 (C2)</td>
            <td>Wheel 1 SWITCH</td>
        </tr>
        <tr>
            <td>KEY_73</td>
            <td>0x0D</td>
            <td></td>
            <td></td>
            <td>Wheel 2 UP</td>
        </tr>
        <tr>
            <td>KEY_74</td>
            <td>0x0E</td>
            <td></td>
            <td></td>
            <td>Wheel 2 DOWN</td>
        </tr>
        <tr>
            <td>KEY_75</td>
            <td>0x0F</td>
            <td></td>
            <td></td>
            <td>Wheel 2 SWITCH</td>
        </tr>
        <tr>
            <td id="comment" colspan="5">Joysticks</td>
        </tr>
        <tr>
            <td>KEY_80</td>
            <td>0x10</td>
            <td></td>
            <td></td>
            <td>Joystick 1 DOWN</td>
        </tr>
        <tr>
            <td>KEY_81</td>
            <td>0x11</td>
            <td></td>
            <td></td>
            <td>Joystick 1 LEFT</td>
        </tr>
        <tr>
            <td>KEY_82</td>
            <td>0x12</td>
            <td></td>
            <td></td>
            <td>Joystick 1 RIGHT</td>
        </tr>
        <tr>
            <td>KEY_83</td>
            <td>0x13</td>
            <td></td>
            <td></td>
            <td>Joystick 1 UP</td>
        </tr>
        <tr>
            <td>KEY_84</td>
            <td>0x14</td>
            <td></td>
            <td></td>
            <td>Joystick 2 DOWN</td>
        </tr>
        <tr>
            <td>KEY_85</td>
            <td>0x15</td>
            <td></td>
            <td></td>
            <td>Joystick 2 LEFT</td>
        </tr>
        <tr>
            <td>KEY_86</td>
            <td>0x16</td>
            <td></td>
            <td></td>
            <td>Joystick 2 RIGHT</td>
        </tr>
        <tr>
            <td>KEY_87</td>
            <td>0x17</td>
            <td></td>
            <td></td>
            <td>Joystick 2 UP</td>
        </tr>
    </table>
    <figcaption>Internal key codes.</figcaption>
</figure>

Table with the keypad mapping lists.

<figure id="keypad-mapping">
    <table>
        <tr>
            <th>TABLE</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>CUSTOM</td>
            <td>0x05</td>
            <td>Codes can be defined by user</td>
        </tr>
        <tr>
            <td>FUNCTIONAL</td>
            <td>0x01</td>
            <td>Scan codes F1-F10</td>
        </tr>
        <tr>
            <td>MULTIMEDIA</td>
            <td>0x04</td>
            <td>Media control (like volume, skip etc.)</td>
        </tr>
        <tr>
            <td>NAVIGATION</td>
            <td>0x02</td>
            <td>Control over cursor, pages etc.</td>
        </tr>
        <tr>
            <td>NUMBER</td>
            <td>0x00</td>
            <td>Numbers 0-9 and decimal dot.</td>
        </tr>
        <tr>
            <td>TELEFON</td>
            <td>0x03</td>
            <td>Cell phone like keyboard.</td>
        </tr>
    </table>
    <figcaption>Mapping tables.</figcaption>
</figure>

Reference to the table with the [HID codes](/hid/hid#hid-codes) available.

Table with Varikey HID scan code values.

<figure id="keypad-scan-code">
    <table>
        <tr style="height:7em">
            <th>KEY_ID</th>
            <th class="small_col">CODE</th>
            <th style="writing-mode:vertical-rl">FUNCTIONAL</th>
            <th style="writing-mode:vertical-rl">MULTIMEDIA</th>
            <th style="writing-mode:vertical-rl">NAVIGATION</th>
            <th style="writing-mode:vertical-lr">default<br>NUMBER</th>
            <th style="writing-mode:vertical-rl">TELEFON</th>
        </tr>
        <tr>
            <td>KEY_01</td>
            <td>0x00</td>
            <td>F1</td>
            <td>ESCAPE</td>
            <td>ESCAPE</td>
            <td>0</td>
            <td>1 , .</td>
        </tr>
        <tr>
            <td>KEY_02</td>
            <td>0x01</td>
            <td>F2</td>
            <td>HELP</td>
            <td>HOME</td>
            <td>1</td>
            <td>2 a b c</td>
        </tr>
        <tr>
            <td>KEY_03</td>
            <td>0x02</td>
            <td>F3</td>
            <td>CUT</td>
            <td>END</td>
            <td>2</td>
            <td>3 d e f</td>
        </tr>
        <tr>
            <td>KEY_04</td>
            <td>0x03</td>
            <td>F4</td>
            <td>COPY</td>
            <td>INSERT</td>
            <td>3</td>
            <td>4 g h i</td>
        </tr>
        <tr>
            <td>KEY_05</td>
            <td>0x04</td>
            <td>F5</td>
            <td>PASTE</td>
            <td>DELETE</td>
            <td>4</td>
            <td>5 j k l</td>
        </tr>
        <tr>
            <td>KEY_06</td>
            <td>0x05</td>
            <td>F6</td>
            <td>PAUSE</td>
            <td>ARROW_UP</td>
            <td>5</td>
            <td>6 m n o</td>
        </tr>
        <tr>
            <td>KEY_07</td>
            <td>0x06</td>
            <td>F7</td>
            <td>STOP</td>
            <td>ARROW_DOWN</td>
            <td>6</td>
            <td>7 p q r s</td>
        </tr>
        <tr>
            <td>KEY_08</td>
            <td>0x07</td>
            <td>F8</td>
            <td>CLEAR</td>
            <td>ARROW_LEFT</td>
            <td>7</td>
            <td>8 t u v</td>
        </tr>
        <tr>
            <td>KEY_09</td>
            <td>0x08</td>
            <td>F9</td>
            <td>CANCEL</td>
            <td>ARROW_RIGHT</td>
            <td>8</td>
            <td>9 w x y z</td>
        </tr>
        <tr>
            <td>KEY_10</td>
            <td>0x09</td>
            <td>F10</td>
            <td>FIND</td>
            <td>SELECT</td>
            <td>9</td>
            <td>0 SPACE CAPS</td>
        </tr>
        <tr>
            <td>KEY_70</td>
            <td>0x0A</td>
            <td>F1-F10</td>
            <td>VOLUME_UP</td>
            <td>PAGE_UP</td>
            <td>0-9 PERIOD</td>
            <td>0-9 a-z</td>
        </tr>
        <tr>
            <td>KEY_71</td>
            <td>0x0B</td>
            <td>F1-F10</td>
            <td>VOLUME_DN</td>
            <td>PAGE_DOWN</td>
            <td>0-9 PERIOD</td>
            <td>0-9 a-z</td>
        </tr>
        <tr>
            <td>KEY_72</td>
            <td>0x0C</td>
            <td>ESCAPE</td>
            <td>MUTE</td>
            <td>ENTER</td>
            <td>PERIOD</td>
            <td>BACKSPACE</td>
        </tr>
        <tr>
            <td>KEY_80</td>
            <td>0x10</td>
            <td colspan="5">ARROW_DOWN</td>
        </tr>
        <tr>
            <td>KEY_81</td>
            <td>0x11</td>
            <td colspan="5">ARROW_LEFT</td>
        </tr>
        <tr>
            <td>KEY_82</td>
            <td>0x12</td>
            <td colspan="5">ARROW_RIGHT</td>
        </tr>
        <tr>
            <td>KEY_83</td>
            <td>0x13</td>
            <td colspan="5">ARROW_UP</td>
        </tr>
    </table>
    <figcaption>HID scan codes.</figcaption>
</figure>

Key level identifier.

<figure id="keypad-key-level">
    <table>
        <tr>
            <th>KEY_LEVEL</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>PRESSED</td>
            <td>0x00</td>
            <td></td>
        </tr>
        <tr>
            <td>RELEASED</td>
            <td>0x01</td>
            <td></td>
        </tr>
    </table>
    <figcaption>Key level.</figcaption>
</figure>

### KEYPAD+REQ 0x30
{: .cmd}

An event request for a manual key press.

<figure id="keypad-req">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>KEYPAD+REQ</td>
            <td>0x30 Command code</td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: HCI/HID eventing control</td>
        </tr>
        <tr>
            <td>1</td>
            <td>IDENTIFIER</td>
            <td>Command identifier 0x72 HCI or 0x73 HDI <a href="#keypad-identifier">(table)</a></td>
        </tr>
        <tr>
            <td>2</td>
            <td>FUNCTION</td>
            <td>Function code 0x02 ENABLE or 0x03 DISABLE <a href="#keypad-function">(table)</a></td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: event MAPPING</td>
        </tr>
        <tr>
            <td>1</td>
            <td>IDENTIFIER</td>
            <td>Command identifier 0x71 MAPPING <a href="#keypad-identifier">(table)</a></td>
        </tr>
        <tr>
            <td>2</td>
            <td>FUNCTION</td>
            <td>Function code 0x01 SET or 0x00 GET <a href="#keypad-function">(table)</a></td>
        </tr>
        <tr>
            <td>3</td>
            <td>TABLE</td>
            <td>Mapping <a href="#keypad-mapping">table</a></td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: backdoor KEYCODE</td>
        </tr>
        <tr>
            <td>1</td>
            <td>IDENTIFIER</td>
            <td>Command identifier 0x74 KEYCODE <a href="#keypad-identifier">(table)</a></td>
        </tr>
        <tr>
            <td>2</td>
            <td>CODE</td>
            <td>Internal keypad event <a href="#keypad-scan-code">CODE</a></td>
        </tr>
    </table>
    <figcaption>KEYPAD request payload structure.</figcaption>
</figure>

The HID and HCI enable/disable command control output site of the engine.
The events are generated but would not be sent, if one or both interfaces are disabled.

Keypad HCI enable example:

<samp id="hci-enable-example">7E 20 01<mark>30 72 02</mark>CC C4 7E</samp>
<button class="copyable" onclick="CopyExample(this)"/>

Keypad change keypad mapping to MULTIMEDIA:

<samp id="keypad-mapping-example">7E 20 01<mark>30 71 01 04</mark>CC C4 7E</samp>
<button class="copyable" onclick="CopyExample(this)"/>

### KEYPAD+CFM 0x31
{: .cmd}

<figure id="keypad-cfm">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>KEYPAD+CFM</td>
            <td>0x31 Command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>RESULT</td>
            <td> Result code <a href="#macro-event-results">Table</a></td>
        </tr>
        <tr>
            <td>2</td>
            <td>IDENTIFIER</td>
            <td>Command <a href="#keypad-identifier">identifier table</a></td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: HCI/HID eventing control</td>
        </tr>
        <tr>
            <td>3</td>
            <td>FUNCTION</td>
            <td>Function code 0x02 ENABLE or 0x03 DISABLE <a href="#keypad-function">(table)</a></td>
        </tr>
        <tr>
            <td>4</td>
            <td>CONTROL</td>
            <td>Control <a href="#keypad-control">entity</a></td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: event MAPPING</td>
        </tr>
        <tr>
            <td>3</td>
            <td>FUNCTION</td>
            <td>Function code 0x01 SET or 0x00 GET <a href="#keypad-function">(table)</a></td>
        </tr>
        <tr>
            <td>4</td>
            <td>TABLE</td>
            <td>Mapping <a href="#keypad-mapping">table</a></td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: backdoor KEYCODE</td>
        </tr>
        <tr>
            <td>3</td>
            <td>CODE</td>
            <td>Internal keypad event <a href="#keypad-scan-code">CODE</a></td>
        </tr>
    </table>
    <figcaption>Payload structure.</figcaption>
</figure>

Example:

<samp>7E 20 01<mark>00 00 00</mark>00 00 7E</samp>

### KEYPAD+IND 0x32
{: .cmd}

This event message signals that at least one user interface event was recorded asynchronously.

<figure id="event-wheel-ind">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>KEYPAD+IND</td>
            <td>0x32 Command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>CONTROL</td>
            <td>Control <a href="#keypad-control">entity</a></td>
        </tr>
        <tr>
            <td>2</td>
            <td>CODE</td>
            <td>HID <a href="/hid/hid#hid-codes">code</a></td>
        </tr>
        <tr>
            <td>3</td>
            <td>LEVEL</td>
            <td>A key level <a href="#keypad-key-level">(table)</a></td>
        </tr>
        <tr>
            <td>4</td>
            <td>CODE</td>
            <td>Internal keypad event <a href="#keypad-scan-code">CODE</a></td>
        </tr>
        <tr>
            <td>5</td>
            <td>TABLE</td>
            <td>Mapping <a href="#keypad-mapping">table</a></td>
        </tr>
    </table>
    <figcaption>KEYPAD confirmation payload structure.</figcaption>
</figure>

Example for HID key event PAGE_DOWN caused by a selection wheel rotation:

<samp>7E 20 01<mark>32 01 4E</mark>6A 44 7E</samp>

Example for HID key event 0 caused by button click:

<samp>7E 20 01<mark>32 01 27</mark>6A 44 7E</samp>

<div class="pagebreak"/>

## IDENTITY
{: .cmd-head}

A keypad can be uniquely identified.

In a scenario with multiple keypads, each connected to the host, the keypads can be individually addressed, and events can be assigned to one of the keypads.

Available identities are listed in the table below.
The code 0xFF UNDEFINED in the FUNCTION field can only appear in a confirmation.

<figure id="identity-part">
    <table>
        <tr>
            <th class="small_col">FUNCTION</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>FIRMWARE</td>
            <td>0xA1</td>
            <td>Firmware identifier</td>
        </tr>
        <tr>
            <td>HARDWARE</td>
            <td>0xA2</td>
            <td>Hardware identifier</td>
        </tr>
        <tr>
            <td>PLATFORM</td>
            <td>0xA4</td>
            <td>Platform name</td>
        </tr>
        <tr>
            <td>PRODUCT</td>
            <td>0xA3</td>
            <td>Product name</td>
        </tr>
        <tr>
            <td>SERIAL</td>
            <td>0xA5</td>
            <td>12 bytes long serial number of the keypad</td>
        </tr>
        <tr>
            <td>UNIQUE</td>
            <td>0xA6</td>
            <td>Unique keypad identifier</td>
        </tr>
    </table>
    <figcaption>Keypad identity identifier</figcaption>
</figure>

The firmware should maintain the revision of the implemented specification. 
The build environment (CMake) defines the variable VERSION with Major, Minor, Patch, and Tweak numbers.

<figure id="firmware-version">
    <table>
        <tr>
            <th class="small_col">Revision</th>
            <th class="byte_col">Value</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>MAJOR</td>
            <td>0-255</td>
            <td>Development phase, interface change</td>
        </tr>
        <tr>
            <td>MINOR</td>
            <td>0-255</td>
            <td>Extension of the interface functionality</td>
        </tr>
        <tr>
            <td>PATCH</td>
            <td>0-255</td>
            <td>Technical improvements, bug fixes</td>
        </tr>
        <tr>
            <td>TWEAK</td>
            <td>0-255</td>
            <td>Internal refactoring</td>
        </tr>
    </table>
    <figcaption>Firmware revision.</figcaption>
</figure>

The build environment provides internal variables `PROJECT_VERSION_MAJOR`, `PROJECT_VERSION_MINOR`, `PROJECT_VERSION_PATCH`, `PROJECT_VERSION_TWEAK` for the mapping. 
An another variable `BUILD_NUMBER` is incremented after each build process.

Mapping of the project variables to the firmware identity fields is shown in the table below.

<figure id="command-byte">
    <table>
        <tr style="text-align:center;width:50px">
            <th>7</th>
            <th>6</th>
            <th>5</th>
            <th>4</th>
            <th>3</th>
            <th>2</th>
            <th>1</th>
            <th>0</th>
            <th>7</th>
            <th>6</th>
            <th>5</th>
            <th>4</th>
            <th>3</th>
            <th>2</th>
            <th>1</th>
            <th>0</th>
        </tr>
        <tr>
            <td colspan="16">FIRMWARE_IDENTIFIER</td>
        </tr>
        <tr>
            <td  colspan="8">PROJECT_VERSION_MAJOR</td>
            <td  colspan="8">PROJECT_VERSION_MINOR</td>
        </tr>
        <tr>
            <td  colspan="8">PROJECT_VERSION_PATCH</td>
            <td  colspan="8">PROJECT_VERSION_TWEAK</td>
        </tr>
        <tr>
            <td colspan="16">BUILD_NUMBER</td>
        </tr>
    </table>
    <figcaption>Mapping of the firmware identifier.</figcaption>
</figure>

The build number distinguishes individual firmware build processes. 
Its value ranges from 0 to 65535 and is incremented independently of the revision with each build. 
However, it should always be interpreted in conjunction with the preceding revision.

In the repository, you'll find an appropriate protocol definition for each firmware release.

Due to the target hardware, the specific keyboard modules may vary from specification and limit the functionality covered in this document.

A firmware with the specific hardware identifier should be created for each hardware variant of a keypad.

The build environment (CMake) should provide the current identifier in a `HARDWARE_IDENTIFIER` variable  and hardware number and variant in the corresponding `HARDWARE_NUMBER` and `HARDWARE_VARIANT` variables.

<figure id="command-byte">
    <table>
        <tr style="text-align:center;width:50px">
            <th>7</th>
            <th>6</th>
            <th>5</th>
            <th>4</th>
            <th>3</th>
            <th>2</th>
            <th>1</th>
            <th>0</th>
            <th>7</th>
            <th>6</th>
            <th>5</th>
            <th>4</th>
            <th>3</th>
            <th>2</th>
            <th>1</th>
            <th>0</th>
        </tr>
        <tr>
            <td colspan="16">HARDWARE_IDENTIFIER</td>
        </tr>
        <tr>
            <td  colspan="8">HARDWARE_NUMBER</td>
            <td  colspan="8">HARDWARE_VARIANT</td>
        </tr>
    </table>
    <figcaption>Mapping hardware identifier.</figcaption>
</figure>

### IDENTITY+REQ 0x14
{: .cmd}

Request for the keypad identifier.

<figure id="identity-req">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>IDENTITY+REQ</td>
            <td>0x14 Command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>FUNCTION</td>
            <td>Code <a href="#identity-part">Table</a></td>
        </tr>
    </table>
    <figcaption>IDENTITY+REQ payload structure.</figcaption>
</figure>

Example for a request for the serial number:

<samp id="identity-serial-example">7E 20 01<mark>14 A5</mark>CF B7 7E</samp>
<button class="copyable" onclick="CopyExample(this)"/>

Example of a request for the platform identifier:

<samp id="identity-platform-example">7E 20 01<mark>14 A4</mark>FF D4 7E</samp>
<button class="copyable" onclick="CopyExample(this)"/>

### IDENTITY+CFM 0x15
{: .cmd}

Command uses the <a href="#common-result-codes">common result codes</a> (field RESULT) only.

#### Serial und unique number identifier
{: .cmd-head}

Confirmation of a request for the keypad's serial number.

<figure id="identity-serial-cfm">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>IDENTITY+CFM</td>
            <td>0x15 Command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>RESULT</td>
            <td>Code <a href="#identity-results">Table</a></td>
        </tr>
        <tr>
            <td id="comment" colspan=3>Option: serial number</td>
        </tr>
        <tr>
            <td>2</td>
            <td>FUNCTION</td>
            <td>Serial number (Code <a href="#identity-part">Table</a>)</td>
        </tr>
        <tr>
            <td>3-14</td>
            <td>SERIAL</td>
            <td>12 bytes long array</td>
        </tr>
        <tr>
            <td id="comment" colspan=3>Option: unique identifier</td>
        </tr>
        <tr>
            <td>2</td>
            <td>FUNCTION</td>
            <td>Unique identifier (Code <a href="#identity-part">Table</a>)</td>
        </tr>
        <tr>
            <td>3-6</td>
            <td>UNIQUE</td>
            <td>4 bytes long integer</td>
        </tr>
    </table>
    <figcaption>IDENTITY+CFM S/N payload structure.</figcaption>
</figure>

Serial number confirmation example:

<samp>7E 20 01<mark>15 00 00 07 E4 CD 99 35 76 D4 8A B4 25 04 81</mark>83 7D 5E 7E</samp>

#### Hardware identifier
{: .cmd-head}

Confirmation with the current hardware revision and variant.

Command uses the <a href="#common-result-codes">common result codes</a> only.

<figure id="identity-hardware-cfm">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>IDENTITY+CFM</td>
            <td>0x15 Command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>RESULT</td>
            <td>Code <a href="#identity-results">Table</a></td>
        </tr>
        <tr>
            <td>2</td>
            <td>FUNCTION</td>
            <td>Hardware identifier 0xA2 HARDWARE (Code <a href="#identity-part">Table</a>)</td>
        </tr>
        <tr>
            <td>3-4</td>
            <td>MAINTAINER</td>
            <td>Value adjustable with a parameter</td>
        </tr>
        <tr>
            <td>5-6</td>
            <td>HARDWARE_IDENTIFIER</td>
            <td>Keypad hardware identifier</td>
        </tr>
        <tr>
            <td>7</td>
            <td>HARDWARE_NUMBER</td>
            <td>Keypad hardware number</td>
        </tr>
        <tr>
            <td>8</td>
            <td>HARDWARE_VARIANT</td>
            <td>Keypad hardware variant</td>
        </tr>
    </table>
    <figcaption>IDENTITY+CFM hardware identifier payload structure.</figcaption>
</figure>

Example:

<samp>7E 20 01<mark>15 00 A2 00 00 A8 34 E3 00</mark>42 0E 7E</samp>

#### Firmware identifier
{: .cmd}

The firmware request returns the firmware revision.
Confirmation of the firmware request for the current revision.

Command uses the <a href="#common-result-codes">common result codes</a> only.


<figure id="identify-firmware-cfm">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>FIRMWARE+CFM</td>
            <td>0x0D Command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>RESULT</td>
            <td>Code <a href="#firmware-results">Table</a></td>
        </tr>
        <tr>
            <td>2</td>
            <td>FUNCTION</td>
            <td>Firmware identifier 0xA1 FIRMWARE (Code <a href="#identity-part">Table</a>)</td>
        </tr>
        <tr>
            <td>3-4</td>
            <td>IDENTIFIER</td>
            <td>Firmware identifier</td>
        </tr>
        <tr>
            <td>5</td>
            <td>VERSION_MAJOR</td>
            <td rowspan="2">Firmware revision</td>
        </tr>
        <tr>
            <td>6</td>
            <td>VERSION_MINOR</td>
        </tr>
        <tr>
            <td>7</td>
            <td>VERSION_PATCH</td>
            <td rowspan="2">Firmware patch</td>
        </tr>
        <tr>
            <td>8</td>
            <td>VERSION_TWEAK</td>
        </tr>
        <tr>
            <td>9-10</td>
            <td>BUILD_NUMBER</td>
            <td>Build number</td>
        </tr>
        <tr>
            <td>11-12</td>
            <td>VENDOR</td>
            <td>Vendor identifier</td>
        </tr>
    </table>
    <figcaption>FIRMWARE+CFM payload-Structure.</figcaption>
</figure>

Example:

<samp>7E 20 01<mark>0D 00 01 00 00 00 00 06</mark>73 02 7E</samp>

#### Product and platform names
{: .cmd}

The firmware request for platform of product name returns a byte coded string.

Command uses the <a href="#common-result-codes">common result codes</a> only.

Confirmation of the name request for the current revision.

<figure id="firmware-cfm-name">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>FIRMWARE+CFM</td>
            <td>0x0D Command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>RESULT</td>
            <td>Code <a href="#firmware-results">Table</a></td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: product name</td>
        </tr>
        <tr>
            <td>2</td>
            <td>FUNCTION</td>
            <td>Product name (Code <a href="#identity-part">Table</a>)</td>
        </tr>
        <tr>
            <td>3-N</td>
            <td>PRODUCT</td>
            <td>Byte array with product name</td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: Platform name</td>
        </tr>
        <tr>
            <td>2</td>
            <td>FUNCTION</td>
            <td>Platform name (Code <a href="#identity-part">Table</a>)</td>
        </tr>
        <tr>
            <td>3-N</td>
            <td>PLATFORM</td>
            <td>Byte array with platform name</td>
        </tr>
    </table>
    <figcaption>FIRMWARE+CFM product/platform payload structure.</figcaption>
</figure>

Example:

<samp>7E 20 01<mark>0D 00 01 00 00 00 00 06</mark>73 02 7E</samp>

<div class="pagebreak"/>

## PARAMETER
{: .cmd-head}

The keypad can be configured at runtime with several parameters. 
Parameters of the keypad firmware can be read from and written into the flash memory.

A list of parameters, along with information about their types and sizes, is available in the subchapter <a href="#scope-parameter">Settings and Parameters</a>.

The function codes for a parameter message are provided in the table below.

<figure id="parameter-functions">
    <table>
        <tr>
            <th class="small_left">FUNCTION</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>GET</td>
            <td>0x00</td>
            <td>Request for the value of a parameter</td>
        </tr>
        <tr>
            <td>SET</td>
            <td>0x01</td>
            <td>Set new value and save</td>
        </tr>
    </table>
    <figcaption>Function codes.</figcaption>
</figure>

For every parameter request, the keypad firmware responds with a confirmation.

The parameter commands uses the <a href="#common-result-codes">common result codes</a>.

Extended result codes for the `RESULT` field in the parameter confirmation are provided in the table below.

<figure id="parameter-results">
    <table>
        <tr>
            <th class="small_left">RESULT</th>
            <th class="small_col">Code</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>STORAGE_ERROR</td>
            <td>0x80</td>
            <td>Read/Write operation failed</td>
        </tr>
    </table>
    <figcaption>Parameter result codes.</figcaption>
</figure>

Caution: In case of a confirmation with `STORAGE_ERROR` in the result field, a keypad restart should be initiated one more time.

Parameter exchange between a host and a keypad occurs synchronously: a confirmation immediately follows a request.
This confirmation contains the stored or accepted values.

### PARAMETER+REQ 0x18
{: .cmd}

Parameter request using the example of a features query. 
Additional parameter codes are listed in the chapter <a href="#persistent-parameters">Persistent Parameters</a>.

<figure id="parameter-req">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>PARAMETER+REQ</td>
            <td>0x18 Command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>PARAMETER</td>
            <td>Parameter <a href="#feature-parameter">FEATURES</a> <a href="#parameter-code">(parameter list)</a></td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: get parameter value</td>
        </tr>
        <tr>
            <td>2</td>
            <td>FUNCTION</td>
            <td>Code 0x00 GET <a href="#parameter-functions">(table)</a></td>
        </tr>
        <tr>
            <td id="comment" colspan="3">Option: set parameter value</td>
        </tr>
        <tr>
            <td>2</td>
            <td>FUNCTION</td>
            <td>Code 0x01 SET <a href="#parameter-functions">(table)</a></td>
        </tr>
        <tr>
            <td>3-N</td>
            <td>VALUE</td>
            <td>Field depends on the parameter definition; <a href="#parameter-code">(parameter list)</a></td>
        </tr>
    </table>
    <figcaption>PARAMETER+REQ payload structure.</figcaption>
</figure>

Example of a request for the value of the `FEATURES` parameter:

<samp>7E 20 01<mark>18 51 00</mark>D7 4C 7E</samp>

### PARAMETER+CFM 0x19
{: .cmd}

Confirmation of a parameter request.

<figure id="parameter-cfm">
    <table>
        <tr>
            <th class="small_left">Byte</th>
            <th class="small_left">Feld</th>
            <th>Description</th>
        </tr>
        <tr>
            <td>0</td>
            <td>IDENTITY+CFM</td>
            <td>0x19 Command code</td>
        </tr>
        <tr>
            <td>1</td>
            <td>RESULT</td>
            <td>Code <a href="#parameter-results">Table</a></td>
        </tr>
        <tr>
            <td>2</td>
            <td>PARAMETER</td>
            <td>Parameter code <a href="#parameter-code">table</a></td>
        </tr>
        <tr>
            <td>3</td>
            <td>FUNCTION</td>
            <td>Code <a href="#parameter-functions">Table</a></td>
        </tr>
        <tr>
            <td>4</td>
            <td>VALUE</td>
            <td>Parameter value</td>
        </tr>
    </table>
    <figcaption>PARAMETER+CFM payload structure.</figcaption>
</figure>

Caution: Field `VALUE` has a variable length. The length of the field depends on the definition of the parameter. These definitions can be found in the chapter "Parameters".

Example: (Parameter `FEATURES`):

<samp>7E 20 01<mark>19 00 51 00 FF</mark>DB 28 7E</samp>

Example (a confirmation with a serial number `07E4CD993576D48AB4250481`):

<samp>7E 20 01<mark>19 00 11 00 07 E4 CD 99 35 76 D4 8A B4 25 04 81</mark>DF 87 7E</samp>

Example (a confirmation with a position LAT:49.4416, LON:11.0538):

<samp>7E 20 01<mark>19 00 24 00 35 C4 45 42 88 DC 30 41</mark>6B 80 7E</samp>

