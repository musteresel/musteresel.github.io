---
title: Migrate a Xen VDI to another storage repository (on the command line)
date: 2018-02-28
language: en
tags: xen
...

I had a virtual disk (VDI) attached to one of my VMs which wasn't full
(according to `df` on the VM) but was causing IO errors for all
applications running in the VM.

Running `xe vm-disk-list vm=$VM` (where in `VM` is either the UUID or
the name of the VM the disk is attached to) shows both the disks as
well as the (names of) the storage repositories these disks are stored
in.  This information is available under `sr-name-label`.

`xe sr-list` gives a complete list of storage repositories, from which
I could find the UUID of the storage repository in question.  Running
`xe sr-param-list uuid=$SRUUID` shows how full the storage repository
is:

```
      virtual-allocation ( RO): 4340072841216
    physical-utilisation ( RO): 1320537186304
           physical-size ( RO): 1320538832896
```

This one is almost completely full.  But I had another storage
repository available that wasn't full.  Thus I moved the VDI from one
storage repository to the other:

```bash
xe vdi-pool-migrate uuid=$VDI sr-uuid=$NEWSRUUID
# prints NEWVDI uuid
```

After some time (depending on the size of the VDI that's moved) this
command returns and prints a new UUID which is the UUID of the moved
VDI.

**Note:** Above command only works when the VM is *running*, which
seemed a bit weird to me, but well ...

Using `xe vm-disk-list` I then checked that the VM has been updated to
use that new VDI, which it thankfully had.

I'm posting this because I had a really hard time finding some
documentation about how to do this *without* XenCenter.
