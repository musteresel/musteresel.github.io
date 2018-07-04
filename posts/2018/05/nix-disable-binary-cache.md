---
title: Disabling Nix substitutes (the "binary cache")
date: 2018-05-17
language: en
tags: nixos
...

I don't have a reliable internet connection at the moment.  Yet still
I need to build some software which I'm working on using `nix-build`.
This shouldn't be an issue, because all `buildInputs` (dependencies of
the the build, so to say) are already in my `/nix/store`.  But,
calling `nix-build` showed me this today:

~~~
warning: unable to download 'https://cache.nixos.org/j7vdysvh2ikm3ksrdd1gzhmm702wg0nq.narinfo': Couldn't resolve host name (6); retrying in 300 ms
warning: unable to download 'https://cache.nixos.org/j7vdysvh2ikm3ksrdd1gzhmm702wg0nq.narinfo': Couldn't resolve host name (6); retrying in 519 ms
warning: unable to download 'https://cache.nixos.org/j7vdysvh2ikm3ksrdd1gzhmm702wg0nq.narinfo': Couldn't resolve host name (6); retrying in 1127 ms
warning: unable to download 'https://cache.nixos.org/j7vdysvh2ikm3ksrdd1gzhmm702wg0nq.narinfo': Couldn't resolve host name (6); retrying in 2757 ms
warning: unable to download 'https://cache.nixos.org/j7vdysvh2ikm3ksrdd1gzhmm702wg0nq.narinfo': Couldn't resolve host name (6); retrying in 4724 ms
warning: unable to download 'https://cache.nixos.org/j7vdysvh2ikm3ksrdd1gzhmm702wg0nq.narinfo': Couldn't resolve host name (6); retrying in 9981 ms
warning: unable to download 'https://cache.nixos.org/j7vdysvh2ikm3ksrdd1gzhmm702wg0nq.narinfo': Couldn't resolve host name (6); retrying in 20990 ms
error: unable to download 'https://cache.nixos.org/j7vdysvh2ikm3ksrdd1gzhmm702wg0nq.narinfo': Couldn't resolve host name (6)
~~~

Not nice.  It took me some time to find the option to tell `nix` to
**not** attempt to download anything it could easily build
locally. *It's `nix-build --option substitute false`.*

Not `--option binary-caches false`, or `--fallback` or whatever.
Let's hope I remember this the next time I need it.
