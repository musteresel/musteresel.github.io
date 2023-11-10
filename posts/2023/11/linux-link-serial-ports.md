---
title: Link two serial ports on linux (and sniff on the traffic)
tags: linux
date: 2023-11-10
language: en
...

I'm working on a system atm where one part communicates with the other over a (full duplex, no flow control) UART connection -- so far nothing extraodinary. Normally when I need to see what's happening in the communication between those two parts (especially if it's timing related) I use a logic analyser and capture the traffic on both wires for later / live analysis.

But having the logic analyser not at hand, I used two UART to USB bridges (FTDI adapters) to connect my laptop to both parts, and then linked those two ports up (with added logging of the output) using `socat`:

~~~
socat -v /dev/ttyUSB0,rawer,b921600 /dev/ttyUSB1,rawer,b921600
~~~

The `-v` tells socat to write any transferred data also to stderr, but with some conversions for readability. And also with a prefix of `>` or `<` to indicate flow direction. One could also use `-x` to get the data as hex (with flow direction indication).

Usage of `rawer` was necessary in my case - most likely to avoid any conversions (line endings?) from happening. The `b921600` is just the baudrate. `socat` of course also has options to specify things like parity and so on. Those options should be documented in `man socat` on any linux distribution.

Side note: This of course affects the timing of the communication line quite a bit! So not really an alternative if timing related issues have to be solved.