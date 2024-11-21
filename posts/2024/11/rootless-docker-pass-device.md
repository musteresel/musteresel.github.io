---
title: Pass a (serial or other) device into rootless docker containers
tags: [linux, embedded]
date: 2024-11-21
language: en
...

I wanted to write some firmware for an ESP chip. I've been using Docker containers for development, specifically via VS Code and the devcontainer extension lately, so naturally I wanted to do the same here and install esp-idf with its tools into a docker container.

Obviously that container then needs to be able to access the ESP device, /dev/ttyUSB0 in my case. To test this, I ran:

~~~bash
$ docker run -it --rm --device=/dev/ttyUSB0 alpine ls -la /dev/ttyUSB0
crw-rw----    1 nobody   nobody     188,   0 Nov 20 14:50 /dev/ttyUSB0
~~~

So in the container, the passed in device is owned by `nobody:nobody` and is thus not accessible even though I'm "root" in the container:

~~~bash
# ... After adding picocom to the container
$ id
uid=0(root) gid=0(root) groups=0(root),1(bin),2(daemon),3(sys),4(adm),6(disk),10(wheel),11(floppy),20(dialout),26(tape),27(video)
$ picocom -b 115200 --imap lfcrlf /dev/ttyUSB0 
picocom v3.1
# ... (info about port settings omitted)
FATAL: cannot open /dev/ttyUSB0: Permission denied
~~~

Outside of the container, `/dev/ttyUSB0` is owned by `root:dialout`. **Now, the device can be made accessible from within the container by changing that to `root:users`** where `users` is the primary group of my user `musteresel`, which is also running the docker daemon. Moreover the docker daemon is also running as this (effective, real) group.

With the group ownership changed I get inside the container:

~~~bash
$ docker run -it --rm --device=/dev/ttyUSB0 alpine ls -la /dev/ttyUSB0
crw-rw----    1 nobody   root      188,   0 Nov 21 19:01 /dev/ttyUSB0
~~~

In other words, the docker container has the group "root" (inside the container) mapped to the group "users" outside the container; in the same way as it has the user "root" (inside the container) mapped to the user "musteresel" (who is running the docker daemon) on the host. For that mapping to work, the two files (on the host) `/etc/subuid` and `/etc/subgid` play an important role.

*Obviously changing the ownership of the device file on the host is not what I really want (even though it is a quick solution ... but well).*

Concentrating only on groups, and thus on the `/etc/subgid` file:

~~~bash
$ cat /etc/subgid
musteresel:100000:65536
~~~

This means (see also `man newgidmap`) roughly that the user "musteresel" is allowed to map GIDs from a user namespace ("inside the container") to group ids on the host starting from GID 100000 up to 100000 + 65536 - 1. This can also be seen when inspecting the gid map of a process inside the container:

~~~bash
# Running in one terminal
$ docker run -it --rm alpine watch -n 100 echo

# In another terminal, we first get the PID of the watch command:
$ ps aux | grep watch
mustere+  982849  0.0  0.0   1612   760 pts/0    S+   19:41   0:00 watch -n 100 echo
# And then we inspect its GID mapping
$ cat /proc/982849/gid_map
         0        100          1
         1     100000      65536
~~~

I do not know why the first line is there (which tells us that group 0 in the container can be mapped to group 100 on the host). But the second line is a directy consequence of the `/etc/subgid` line, meaning the groups 1 up to groups 1 + 65536 - 1 (inside the container) will be mapped to groups 100000 up to 100000 + 65536 - 1.

What we need in order to access `/dev/ttyUSB0` with group ownership (on the host) `dialout` is a way to map a GID (inside the container) to that GID of the `dialout` group on the host. For that we can add a line to `/etc/subgid`:

~~~bash
$ cat /etc/subgid
musteresel:100000:65536
musteresel:27:1
~~~

`dialout` has GID 27 on my host system; therefore user "musteresel" can now map one (1) GID (of unspecified number atm) inside the container to the one GID 27 on the host. This is also visible if we again inspect the `gid_map`:

~~~bash
$ cat /proc/982878/gid_map
cat /proc/982849/gid_map 
         0        100          1
         1     100000      65536
     65537         27          1
~~~

Now we see that GID 65537 (inside the container) is mapped to GID 27 (`dialout`) outside of the container. If we now inspect the device file (with its original ownership of `root:dialout` on the host) in a docker container:

~~~bash
$ docker run -it --rm --device=/dev/ttyUSB0 alpine ls -la /dev/ttyUSB0
crw-rw----    1 nobody   65537     188,   0 Nov 21 19:45 /dev/ttyUSB0
~~~

Now this device file has a proper group inside the container. I can now either use the `--group-add` flag to docker (with the GID from inside the container 65537) or just create a group inside the container and add root to it:

~~~bash
# Inside the container, picocom already installed
$ ls -la /dev/ttyUSB0
crw-rw----    1 nobody   65537     188,   0 Nov 21 19:45 /dev/ttyUSB0
$ picocom -b 115200 --imap lfcrlf /dev/ttyUSB0
# ... (some output omitted)
FATAL: cannot open /dev/ttyUSB0: Permission denied
# Add a group with that number, and add root to it
$ addgroup -g 65537 host_dialout
$ adduser root host_dialout
# Get a new shell with the new group available
$ su
$ id
uid=0(root) gid=0(root) groups=65537(host_dialout),0(root),0(root),1(bin),2(daemon),3(sys),4(adm),6(disk),10(wheel),11(floppy),20(dialout),26(tape),27(video)
$ ls -la /dev/ttyUSB0
crw-rw----    1 nobody   host_dia  188,   0 Nov 21 19:45 /dev/ttyUSB0
$ picocom -b 115200 --imap lfcrlf /dev/ttyUSB0
# This works now, output omitted :)
~~~

... now, quite honestly -- this is a lot more work and changes to the host than I want. Moreover, on different hosts (development machines) the GID of dialout on the host and also the resulting GID inside the host may be different. So building a single container image to fit them all is difficult (not impossible, just grab the device file GID at runtime and change the GID of some previously created group to that). But hey, it works.

Side note: To make the addition to `/etc/subgid` on my NixOS machine I had to add to my `configuration.nix`:

~~~nix
# More stuff ...
  users.users.musteresel = {
# More stuff ...
    subGidRanges = [
      {
        startGid = 100000;
        count = 65536;
      }
      {
        startGid = config.users.groups.dialout.gid;
        count = 1;
      }
    ];
    subUidRanges = [
      {
        startUid = 100000;
        count = 65536;
      }
    ];
  };
# More stuff ...
~~~

Some related links:

* <https://stackoverflow.com/q/24225647/1116364>
* <https://stackoverflow.com/a/76685087/1116364>
* <https://discourse.nixos.org/t/docker-userns-remap/42805>
* <https://discourse.nixos.org/t/how-to-refer-to-another-users-uid-gid/4045>
* <https://stackoverflow.com/questions/68139659/is-there-a-way-to-see-the-actual-computed-generated-output-system-configurat>


**Ok, if you've managed to follow my ramblings so far, here's what I ended up doing:**

The devcontainer will later of course have the root folder of the firmware source code mounted as volume. So any files inside there will be accessible to the container. Now, the devcontainer just assumes the existence of an `esp` file in the toplevel directory of the workspace; and will use that as device file (as it would `/dev/ttyUSB0`).

On each development machine I create that file (outside of the container) by taking major and minor number of the "real" device file `/dev/ttyUSB0`, creating a new device file named "esp" and changing the ownership accordingly:

~~~bash
# Still on the host
$ ls -la /dev/ttyUSB0 
crw-rw---- 1 root dialout 188, 0 21. Nov 22:15 /dev/ttyUSB0
# From above, take the "c" (character device), the "188" (major) and "0" (minor) values
$ sudo mknod esp c 188 0
$ sudo chown musteresel:users esp
$ ls -la .
# other directory contents omitted
crw-r--r--  1 musteresel users 188, 0 21. Nov 22:10 esp
# Now get into the container
$ docker run -it --rm -v .:/workspace alpine ls -la /workspace
total 8
drwxr-xr-x    2 root     root          4096 Nov 21 21:10 .
drwxr-xr-x    1 root     root          4096 Nov 21 21:22 ..
crw-r--r--    1 root     root      188,   0 Nov 21 21:10 esp
# File can be used normaly in the container now
~~~

This has the benefit that it requires no special configuration for docker, neither on the host nor in the image. I can just create the new device file (as required on each development machine) and it works. It also works when unplugging and replugging the device - and at least on my laptop also if I plug the device into a different usb port. Of course this falls apart if I plug in more devices of the same kind, in varying orders - but in my use case I just have a single ESP board here and that's it.
