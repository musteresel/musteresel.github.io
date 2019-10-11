---
title: A regex to find C/C++ preprocessor includes
date: 2019-10-10
language: en
tags: [c, c++]
...

Yes I know .. "parsing" C or C++ with regular expressions is bad.
There's of course libclang ([1][], [2][]) and also some way to hook
into GCC ... but sometimes it's just easier to slap a regex on the
problem.  In this case **getting the names of the directly included
files**:

~~~bash
grep -oP '#[[:blank:]]*include[[:blank:]]*("|<)\K[\w.\/]+(?=("|>))' FILE
~~~

This calls grep with "Perl-compatible" regex support (`-P`) and prints
only the matches (`-o`).  The regex:

  - `#` ... literally that character
  - `[[:blank:]]*`: some amount of whitespace; except newlines
  - `include` ... literally that word
  - `[[:blank:]]*`: again some whitespace; no newlines
  - `("|<)`: Either `"` or `<`
  - `\K` resets the starting point of the reported match. This
    basically means "only treat the following part of the match as
    *the* match" (which is then printed by grep)
  - `[\w.\/]+` 1 or more of "word characters" (a-z and A-Z), the
    literal dot `.` or forward slashes `/`
  - `(?=     )` is a "positive lookahead" ... meaning make sure that
    this comes next, but don't add it the *the* reported match.
  - `("|<)` (inside the positive lookahead): Either `"` or `>`
  
I've found this regex to work well in practice, though of course it
may return false positives due to:

 - `#include` in comments; these will be picked up, too
 - `#include <foo"` and `#include "foo>` will be picked up, too.  This
   could be fixed ... but honestly ... I don't think that this is a
   likely case to happen
   
And of course it doesn't care about conditional compilation ... so
this will yield `foo`:

~~~c
#if 0
#include "foo"
#endif
~~~

But that's exactly what I need in my case.


[1]: https://clang.llvm.org/doxygen/group__CINDEX.html
[2]: https://clang.llvm.org/docs/Tooling.html
