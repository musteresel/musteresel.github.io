---
title: sudo, but for groups
tags: [linux]
date: 2025-11-04
language: en
...

Ever had the situation that you need your Linux user to be in some special group (looking at you, dialout and docker) in order to perform some operation? Somehow I've never realized that good old `sudo` can not only change your effective user id, but also the group:

~~~
groups
# users wheel dialout networkmanager plugdev adbusers
sudo -g docker groups
# docker wheel dialout networkmanager users plugdev adbusers
~~~

Nice.
