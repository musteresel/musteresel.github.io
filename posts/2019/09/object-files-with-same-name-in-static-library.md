---
title: Object files with same name in a static library are possible!
date: 2019-09-23
language: en
tags: [c, c++, cmake]
...

The setup:

~~~bash
# find . -type f
./foo/name.c
./bar/name.c
./CMakeLists.txt
~~~

The two `name.c` files each define a (dummy) function, with different
names though!

`CMakeLists.txt` contains:

~~~cmake
cmake_minimum_required(VERSION 3.12)
add_library(foo OBJECT foo/name.c)
add_library(bar OBJECT bar/name.c)
add_library(final STATIC $<TARGET_OBJECTS:foo> $<TARGET_OBJECTS:bar>)
~~~

It creates two `OBJECT` libraries with names `foo` and `bar`, and a
`libfinal.a` static library out of the object files of these two.

Inspecting the created `libfinal.a` shows:

~~~bash
# ar t libfinal.a 
name.c.o
name.c.o
~~~

So both object files are in the library.  Showing the offset of these
files also clearly shows that these are different files:

~~~bash
# ar tO libfinal.a 
name.c.o 0x94
name.c.o 0x570
~~~

Linking will search these libraries for the required symbols and just
link them if necessary; the names don't come into play there.  Except
of course in error messages / debugging output, so it would be
*really* helpful if CMake could add a prefix to the object files
somehow ... I only found an unanswered [post on the mailing
list][mail-list-post] from 2014, though.

[mail-list-post]: https://cmake.org/pipermail/cmake/2014-April/057340.html
