---
title: Get the path "up" from some file to some directory
tags: shell
date: 2017-04-15
language: en
...

Say you have some file `foo/bar/baz.txt` ... and you want to know the
path "up" from that file to the directory `foo`.  In this example,
this would be `../..`.  For that I'm using the following in my
Makefile:

```makefile
path_up = realpath -m --relative-to $(abspath $(dir $@)) $(CURDIR)
# later used like:
$(shell $(path_up))
```

As a shell command outside of a Makefile this can look like this:

```shell
realpath -m --relative-to  $(dirname FILE) BASEDIR
```

Note that this is the `realpath` command from the GNU coreutils.  As
noted in [this answer on UNIX Stack Exchange][realpath-se] there are
many different implementations of `realpath` with different features.

[realpath-se]: https://unix.stackexchange.com/a/136527/23529
