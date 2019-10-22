---
title: Running Golden tests with CMake
language: en
date: 2019-10-21
tags: [c++, c, cmake]
...

"Golden tests" are tests which run a tool and compare it's output to
files with expected outputs, the so called *golden files*.

To run such a golden test, the following steps are necessary:

 1. Compile the tool, if it's not already existing.
 2. Run the tool with some input, capturing its output.
 3. Compare the output with the expected output.
 
To show how this can be done with CMake I use a small example project:

~~~c++
/// src/implementation-to-test.cc
bool CountLines(std::istream & in, unsigned & lines)
{
  char c;
  while (in.get(c))
  {
    if (c == '\n') ++lines;
  }
  return ! c.bad();
}
~~~

To test this function I write a "tool" which uses it:

~~~c++
/// test/tool.cc
int main(int argc, char **argv)
{
  // Error handling ommitted
  std::ifstream in(argv[1]);
  std::ofstream out(argv[2]);
  unsigned lines = 0;
  if (! CountLines(in, lines))
  {
    out << "Error\n";
    return 1;
  }
  out << lines << "\n";
}
~~~

Now for the CMake part, there's a top level `CMakeLists.txt` which
creates a library from all the "implementation" files (if the end
result should be an executable, then using a static library and
linking against that works fine):

~~~cmake
# top level CMakeLists.txt
# example for executable as end result
add_library(lib STATIC
  src/one.cc
  src/implementation-to-test.cc
  # ... probably more
  )
add_executable(exe src/main.cc)
target_link_libraries(exe lib)

enable_testing()
add_subdirectory(test)
~~~

So much for the setup, now to the important `test/CMakeLists.txt`
which generates `tool` from `test/tool.cc` and the `lib` library and
runs it:

~~~cmake
# test/CMakeLists.txt

# 1) Create tool
add_executable(tool EXCLUDE_FROM_ALL tool.cc)
target_link_libraries(tool lib)


# 2) Run tool with an input to produce some output
add_test(NAME golden-1-run
  COMMAND
  tool ${CMAKE_CURRENT_SOURCE_DIR}/golden-1-in golden-1-out)


# 3) Compare output with expected output
add_test(golden-1-cmp
  ${CMAKE_COMMAND} -E compare_files
  golden-1-out
  ${CMAKE_CURRENT_SOURCE_DIR}/golden-1-expected)


# A) cmake extra; run compare (3) only when running the tool
#    worked (2), and run that (2) only when the tool is actually
#    built (1)
add_test(tool_build
  "${CMAKE_COMMAND}"
  --build "${CMAKE_BINARY_DIR}"
  --config $<CONFIG>
  --target tool
  )
set_tests_properties(tool_build
  PROPERTIES FIXTURES_SETUP tool_fixture)
set_tests_properties(golden-1-run
  PROPRETIES FIXTURES_REQUIRED tool_fixture)
set_tests_properties(golden-1-run
  PROPERTIES FIXTURES_SETUP golden-1_fixture)
set_tests_properties(golden-1-cmp
  PROPERTIES FIXTURES_REQUIRED golden-1_fixture)
~~~


There's a few things going on ...

 1. The `tool` exectuable is created.  It links to the (static in this
    case) `lib` library with the implementation and will thus directly
    use (and test) that compiled code.
    
    One important thing: I've specified `EXCLUDE_FROM_ALL` which means
    the `tool` executable won't be built by `make all` **or even `make
    test`**.  This requires some boiler plate code (explained further
    down in "A)").  Removing the `EXCLUDE_FROM_ALL` means the tool
    will be built by `make` / `make all` ... but *still* not by `make
    test`.  This is a known bug / short comming of CMake, see [this
    stackoverflow.com answer and the questions / other
    answers][so-cmake-bug] for more.
    
    [so-cmake-bug]: https://stackoverflow.com/a/56448477/1116364
    
 2. Specify a golden test ("golden-1-run") which runs the tool with an
    input file (`golden-1-in`) to produce some output (`golden-1-out`).

    I use the `add_test(NAME .. COMMAND tool ..)` version of
    `add_test` because [that uses the full path][add-test] to the
    `tool` exectuable (from the `tool` target) to run the test and
    thus does not interfere with possibly available other commands
    (think of `test` ...).
    
    This reads the input file from the current source directory (the
    directory where that `CMakeLists.txt` is) and writes the output
    into the current binary directory.
    
 3. Specify the compare step of the golden test ("golden-1-cmp").
    This uses the CMake command `compare_files` to compare the output
    produced by the previous test to the expected output from the
    *golden file* (`golden-1-expected`).
    
    The expected output file comes from the current source directory,
    whereas the generated output file is in the current binary
    directory.
    
    One short comming of using the CMake `compare_files` command: it
    cannot show what's different, it just compares the files.  For
    that using `diff` would be an option.
    
 And last but not least, the boiler plate code from `A)` ...
 
  - `tool_build` is a "test" which runs CMake itself to build the
    `tool` target, thus making sure that the `tool` executable is
    actually there.  Drawback: The build output is part of the test
    logs.

  - Running any test which runs `tool` doesn't make sense when `tool`
    failed to build.  Similarly, running the compare step doesn't make
    sense when running the tool with the input failed.  Thus
    dependencies between these tests are needed.  For tests,
    dependencies are best modeled by using fixtures.
    
**Fixtures** in CMake are modelled with 3 properties:
[`FIXTURES_SETUP`][fix-setup], [`FIXTURES_CLEANUP`][fix-clean] and
[`FIXTURES_REQUIRED`][fix-req].  The last one - `FIXTURES_REQUIRED` - is set on a
test which *needs* a fixture.  The other two *define* the fixture:
Tests marked with `FIXTURES_SETUP` "setup" the fixture ... so they're
run before any test which needs the fixture.  Test marked with
`FIXTURES_CLEANUP` are run after any tests which needs the fixture and
do "cleanup" tasks.

In the example, there are two fixtures - `tool_fixture` and
`golden-1_fixture` - which each have a single setup test associated
with them.  The relationship is probably best to understand when
visualized, so I've made an ASCII drawing:

~~~
vvvvvvvvvvvvvv
| tool_build |
^^^^^^^^^^^^^^
     A
     | calls for setup
     |
|--------------|               vvvvvvvvvvvvvvvv
| tool_fixture | <<---needs--- | golden-1-run |
|--------------|               ^^^^^^^^^^^^^^^^
                                    A
                                    | calls for setup
                                    |
vvvvvvvvvvvvvvvv               |------------------|
| golden-1-cmp | ---needs--->> | golden-1_fixture |
^^^^^^^^^^^^^^^^               |------------------|
~~~

So running `ctest -R golden-1-cmp` now runs first the `tool_build`
test (building the `tool` exectuable), if that succeeds it runs
`golden-1-run` (which produces the output) and only if that also
succeeds it runs the requested `golden-1-cmp` test.

All that boilerplate CMake code can be put into a function to make it
easier to define golden test.  I've written one adjusted for my own
project ... which I'll generalize and publish if I have the time to do
so.

[add-test]: https://cmake.org/cmake/help/latest/command/add_test.html?highlight=command-line
[fix-req]: https://cmake.org/cmake/help/latest/prop_test/FIXTURES_REQUIRED.html
[fix-setup]: https://cmake.org/cmake/help/latest/prop_test/FIXTURES_SETUP.html
[fix-clean]: https://cmake.org/cmake/help/latest/prop_test/FIXTURES_CLEANUP.html
