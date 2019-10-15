---
title: CMake and a relative path to an installed linker script
language: en
date: 2019-10-15
tags: [cmake, c, c++]
...

Scenario: A static library `lib` is to be installed.  To link against
this static library requires special link flags and a linker script
`script.ld`.

For "GCC compatible" linkers the linker script is specified via the
`-T` flag, followed by the path to the script.  During build of the
static library itself the linker script is within the project source
directory; referencing that is no different than any other file.
Assuming the linker script is put under
`${CMAKE_INSTALL_PREFIX}/share/script.ld` when installed the
straightforward solution looks like this:

~~~cmake
# -T path/to/script.ld for build and install case
target_link_options(lib INTERFACE
  -T $<BUILD_INTERFACE:script.ld> $<INSTALL_INTERFACE:share/script.ld>)

# actually install script.ld file
install(FILES script.ld DESTINATION share/)

# install liblib.a library, prepare export
install(TARGETS lib
  EXPORT lib-target
  ARCHIVE DESTINATION lib/)
  
# install export (cmake files to be used by consumers of the lib)
install(EXPORT lib-target
  FILE libTargets.cmake
  NAMESPACE lib::
  DESTINATION cmake/)
~~~

This works as expected; assuming an empty `${CMAKE_INSTALL_PREFIX}` it
produces a `/lib/liblib.a`, a `/share/script.ld` and a
`/cmake/libTargets.cmake` (and probably also a
`/cmake/libTargets-noconfig.cmake`) when installing via `make install`.

If `/cmake/` is part of the CMake module search path or if
`-Dlib_DIR=/cmake` is specified then the library can be used in
another CMake build using `find_package(lib)` and
`target_link_libraries(target lib::lib)`.  The link flags will contain
`-T /share/script.ld` and of course this path is valid, so everything
is working fine.

**This does not work together with a staging directory (`DESTDIR`),
though!**

E.g. for the library `make install DESTDIR=/stage` is called (perhaps
because the library shall not actually be installed).  Now using the
"almost installed" library in `/stage` from another CMake build
(e.g. `-Dlib_DIR=/stage/cmake`) works fine (the `liblib.a` is found as
would any installed public headers) *except* for the linker script.
Its path is hard wired to `/share/script.ld` after installing (even
if only "almost").  The script is in `/stage/share/script.ld`, though.

To fix this the best is to look at what happens with the path to
`liblib.a`, because somehow CMake can find it even in the "almost
installed" `/stage` directory:

`/stage/cmake/libTargets.cmake` includes (relative to itself)
`libTargets-noconfig.cmake`.  That later file contains code similar
to:

~~~cmake
set_target_properties(lib::lib PROPERTIES
  IMPORTED_LOCATION_NOCONFIG "${_IMPORT_PREFIX}/lib/liblib.a")
~~~

What's `${_IMPORT_PREFIX}`? It's a variable computed in
`/stage/cmake/libTargets.cmake`:

~~~cmake
# Compute the installation prefix relative to this file.
get_filename_component(_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" PATH)
# Use original install prefix when loaded through a
# cross-prefix symbolic link such as /lib -> /usr/lib.
get_filename_component(_realCurr "${_IMPORT_PREFIX}" REALPATH)
get_filename_component(_realOrig "/cmake" REALPATH)
if(_realCurr STREQUAL _realOrig)
  set(_IMPORT_PREFIX "/cmake")
endif()
unset(_realOrig)
unset(_realCurr)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
#
# (HERE, read about it below)
#
if(_IMPORT_PREFIX STREQUAL "/")
  set(_IMPORT_PREFIX "")
endif()
~~~

This basically walks up from the location of `libTargets.cmake` to
where `${CMAKE_INSTALL_PREFIX}` would be.  In this case, since
`libTargets.cmake` is to be installed in
`${CMAKE_INSTALL_PREFIX}/cmake/` it goes up just one level (at the
`HERE` comment), but if it had been put e.g. to
`${CMAKE_INSTALL_PREFIX}/lib/share/cmake/` then there would be 3
`get_filename_component` calls instead of just one.

That way, at "use time" (e.g. during the `find_package(lib)` call)
CMake uses `/stage/cmake/libTargets.cmake` to compute an
`${_IMPORT_PREFIX}` of `/stage` which allows it to use
`${_IMPORT_PREFIX}/lib/liblib.a` to refer to `/stage/lib/liblib.a` -
the correct path to the static library.  **The important point is that
this happens not as part of the configure / build / install process of
the library, but rather during the configuration of another CMake
build (which uses `find_package(lib)`)**.

Fixing the issue with the path to the linker script can be done in (at
least) two ways now:

CMake already computes the very helpful `_IMPORT_PREFIX` variable.  In
order to get "access" to it code needs to be either in
`libTargets.cmake` or in any file included from that file.  Modifying
the *generated* file `libTargets.cmake` is not a good idea, but
thankfully `libTargets.cmake` contains code to include files
`libTargets-*.cmake` (like `libTargets-noconfig.cmake`):

~~~cmake
# Load information for each installed configuration.
get_filename_component(_DIR "${CMAKE_CURRENT_LIST_FILE}" PATH)
file(GLOB CONFIG_FILES "${_DIR}/libTargets-*.cmake")
foreach(f ${CONFIG_FILES})
  include(${f})
endforeach()
~~~

A custom `libTargets-script.cmake` file installed to `cmake/` has
therefore access to `_IMPORT_PREFIX` and can use it to set link
options appropriately:

~~~cmake
# contents of libTargets-script.cmake
# note use of namespaced target name!
target_link_options(lib::lib
  INTERFACE
  -T ${_IMPORT_PREFIX}/share/script.ld)
~~~


*Whether* this is "supported" (it works, but will it in the future?)
by CMake? *I don't know*.

A thus possibly more robust (but also more verbose) approach is to
recreate what CMake does with the `_IMPORT_PREFIX` variable in a
(self-written) `libConfig.cmake`, to be installed to `cmake/`:

~~~cmake
# contents of libConfig.cmake.in
get_filename_component(MYDIR "${CMAKE_CURRENT_LIST_FILE}" PATH)

if (NOT TARGET lib::lib)
  include("${MYDIR}/multipleTargets.cmake")
endif ()

# Compute the installation prefix relative to this file, like 
# CMake does in libTargets.cmake .. this needs to be kept in sync and
# needs to be adjusted e.g. if the (installed) path to this file changes
get_filename_component(_IMPORT_PREFIX "${CMAKE_CURRENT_LIST_FILE}" PATH)
get_filename_component(_realCurr "${_IMPORT_PREFIX}" REALPATH)
get_filename_component(_realOrig "@CMAKE_INSTALL_PREFIX@/cmake" REALPATH)
if(_realCurr STREQUAL _realOrig)
  set(_IMPORT_PREFIX "@CMAKE_INSTALL_PREFIX@/cmake")
endif()
unset(_realOrig)
unset(_realCurr)
get_filename_component(_IMPORT_PREFIX "${_IMPORT_PREFIX}" PATH)
if(_IMPORT_PREFIX STREQUAL "/")
  set(_IMPORT_PREFIX "")
endif()

# note use of namespaced target name!
target_link_options(lib::lib
  INTERFACE
  -T ${_IMPORT_PREFIX}/share/script.ld)
~~~

The above file is `libConfig.cmake.in`, which needs to undergo
substitution of `@CMAKE_INSTALL_PREFIX@` via `configure_file()` with
`@ONLY` before installing.

With either of these approaches it is possible to install a linker
script and use it from other builds, even if the installation was only
to a staging directory.  And of course the staging directory can be
moved around freely ... e.g `mv /stage /somewhere/else` doesn't break
the build.

Finally, this works for every path, e.g. also paths to data files.
