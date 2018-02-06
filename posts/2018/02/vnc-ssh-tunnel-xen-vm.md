---
title: VNC over SSH tunnel to Xen VM
tags: xen
date: 2018-02-06
language: en
...

Some time ago I [accessed the "console" of a Xen VM over a http
tunnel][xen-console-http-post], which was working but rather
unpleasant due to a crippled terminal.  Today I needed to the same
again, so I set out to look for a more comfortable alternative...

Thankfully, I do have SSH access to the Xen server on which my VM is
running, so following [this post from Citrix][citrix-post] I am able
to work with my VM without having to use XenCenter or a similar
software:

 1. Connect to the Xen Server per SSH, and run the following commands
    there.
 2. Get the "domain id" of the virtual machine and the "host uuid" of
    the host it is running on (important when the Xen server manages
    multiple hosts), where `LABEL` is my virtual machine's label:
    
    ```bash
    xe vm-list params=dom-id,resident-on name-label=LABEL
    # resident-on ( RO)    : UUID
    #          dom-id ( RO): DOMID
    ```

 3. If the Xen server manages multiple hosts, then get the IP of the
    host on which the virtual machine is running:
    
    ```bash
    xe pif-list management=true params=IP host-uuid=UUID
    # IP ( RO)    : HOSTIP
    ```
    
    Connect per SSH to that host, and run the following command
    there.
 4. Get the VNC port of the virtual machine:

    ```bash
    xenstore-read /local/domain/DOMID/console/vnc-port
    # PORT
    ```

 5. On the local machine, open a SSH tunnel to the host and redirect a
    local port (`LOCALPORT`) to the host's `localhost:PORT` (where
    `PORT` is the VNC port from above):
    
    ```bash
    ssh -L LOCALPORT:localhost:PORT HOSTIP
    ```

 6. Use some VNC viewer on the local machine and connect to
    `localhost:LOCALPORT`

This works extremely well, just a bit laggy sometimes, but certainly
good enough to setup a SSH server on the virtual machine.


[xen-console-http-post]: /posts/2017/07/xen-vm-console-connection.html
[citrix-post]: https://www.citrix.com/blogs/2011/02/18/using-vnc-to-connect-to-a-xenserver-vms-console/
