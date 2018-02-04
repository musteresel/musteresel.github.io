---
title: Open a console connection to a Xen VM
tags: xen
date: 2017-07-11
language: en
...

I need to setup some virtual machines running on a Xen server which
don't have a ssh server running yet.  One can access such VMs easily
with Xen management software like XenCenter, but I prefer the UNIX
philosophy "do one thing and do it well" and instead have a tool to do
*just* that: give me a connection to one console of one virtual
machine of some Xen server.

It took me a while to dig out the correct Xen API calls, but
[description of consoles of the
xapi-project](http://xapi-project.github.io/xen-api/consoles.html)
sums it up pretty well.  In short:

 1. Login at the Xen server to create new session with
    `Session.login_with_password`
 2. Get a reference to the virtual machine, e.g. by name with
    `VM.get_by_name_label`
 3. Get a list of consoles of that VM: `VM.get_consoles`
 4. Find a console with protocol `vt100` by looking at
    `console.get_protocol`
 5. Get the "location" of the console: `console.get_location`
 6. Depending on the locations protocol ...
    - if it's `https`, then use
      [`gnutls-cli`](https://www.gnutls.org/manual/html_node/gnutls_002dcli-Invocation.html)
      or [`openssl
      s_client`](https://wiki.openssl.org/index.php/Manual:S_client(1)),
      ...
    - otherwise (`http`) using `telnet` is sufficient to connect to
      the location's host
 7. Encode username and password for authorization:

    ```
    echo -n "user:pass" | base64
    ```
    
 8. send, **with CR-LF line endings** and *two* empty lines at the
    end:
    
    ```
    CONNECT <location> HTTP/1.1
    Authorization: Basic <encoded-user-pass>
    
    
    ```
 9. use connection as `vt100` terminal.
 
Doing this manually on the command line actually worked pretty well,
except the terminal was "crippled" (the local terminal probably needs
to be configured somehow, probably like done in
[miniterm](https://github.com/pyserial/pyserial/blob/master/serial/tools/miniterm.py)).
It worked good enough to install an ssh server, though.

The same should work with VNC consoles, too.  Then I could setup a
local port and redirect any traffic to the remote connection which I
previously would set up like described above.  Any VNC viewer should
then be able to connect to my local port.

Also note that - contrary to the Xen API docs (shipped with the Xen
SDK) - one needs to make the HTTP connect request with `HTTP/1.1` (got
the idea to try this from [this only partly related
discussion](https://discussions.citrix.com/topic/243319-how-to-retrieve-vnc-consoles-via-the-xenserver-sdk-api/)).
