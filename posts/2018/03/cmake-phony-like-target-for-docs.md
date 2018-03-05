---
title: Phony-like target for generating documentation with CMake
date: 2018-03-04
language: en
tags: cmake
...

For a CMake based project, my package manager (Nix) runs the following
commands (plus some magic that isn't relevant to this post):

 1. CMake itself, with various flags to specify the non-FHS filesystem
    locations.
 2. `make` to build the project.
 3. `make check` if tests should be run.
 4. `make install` with some flags to create the final package.

My current project has some (Doxygen based) documentation that I'd
like to be built and also installed.  The simplest way to do this
seemed to be:

```cmake
add_custom_target(doc ALL
  COMMAND ${DOXYGEN_COMMAND})
```

The `ALL` specifies that this target should be added to the default
build target.  Furthermore, a target added like this has no "output"
file and is thus *always* considered out of date.

Due to this Doxygen gets called twice: First during `make` and then
again during `make check`.  **Suboptimal.**

I [asked for help][so-question] and got a solution that comes down to:

```cmake
set(documentation_file ${CMAKE_BINARY_DIR}/doc_ready)
add_custom_target(doc ALL
  DEPENDS ${documentation_file})
add_custom_command(OUTPUT ${documentation_file}
  COMMAND ${DOXYGEN_COMMAND}
  COMMAND ${CMAKE_COMMAND} -E touch ${documentation_file})
```

This creates a `doc_ready` file that indicates whether the
documentation has already been built.  Thus the `doc` target is still
always considered out of date, but the documentation is actually build
by its file dependency, which is never out of date since it hasn't any
dependencies. **Wait!**

*Never* out of date is an issue: Running `make doc` manually
(e.g. while developing) now does not rebuild the documentation (it
does nothing on subsequent runs).  For that one needs to either:

 - Delete the `doc_ready` file, or
 - Specify all the file dependencies (source files, images, ...) for
   the Doxygen build.

The second option would be the "cleaner" one, but it's annoying.  To
delete the `doc_ready` file I added another target which does exactly
that ... after first generating the documentation:

```cmake
add_custom_target(doc-manual
  COMMAND ${CMAKE_COMMAND} -E remove ${documentation_file})
add_dependencies(doc-manual doc)
```

`add_dependencies` is necessary because `DEPENDS` (in
`add_custom_command`) should only be used for files, not other
targets.

Now I can run `make doc-manual` when I want to update the built
documentation during developing, and have Nix build the documentation
only once during `make` (and no longer during `make check`).

[so-question]: https://stackoverflow.com/q/49083580/1116364
