---
title: iostream, exceptions and g++
date: 2017-05-17
language: en
tags: c++
---

So you like exceptions?  You always write a wrapper function to get an
`std::istream` (or `std::ostream`) with exceptions enabled? And you
like C++11? Or newer? Then here's some bad news:

```c++
#include <iostream>
#include <fstream>
#include <typeinfo>


int main() {
  std::cout << "Let's try to catch "
            << typeid(std::ios_base::failure).name() << std::endl;
  try {
    std::ifstream stream;
    // Enable exceptions to be thrown on the stream
    stream.exceptions(std::ifstream::failbit
                      | std::ifstream::badbit
                      | std::ifstream::eofbit);
    // Now open a nonexisting file. This will set failbit and thus
    // throw std::ios_base::failure.
    stream.open("NONEXISTING");
  } catch (std::ios_base::failure const & exception) {
    std::cout << "caught std::ios_base::failure. what(): "
              << exception.what() << std::endl;
  } catch (std::exception const & exception) {
    std::cout << "caught std::exception. what(): "
              << exception.what() << std::endl
              << "  type: " << typeid(exception).name() << std::endl;
  }
}
```

This *should* catch an `std::ios_base::failure` exception, but if you
compile above code with g++ 5.x or 6.x, then you'll end up catching an
`std::exception` instead!

```
Let's try to catch NSt8ios_base7failureB5cxx11E
caught std::exception. what(): basic_ios::clear
  type: NSt8ios_base7failureE
```

Why is that?  Well, in C++03 `std::ios_base::failure` derived directly
from `std::exception`.  But in C++11, this was changed such that
`std::ios_base::failure` now derives from `std::runtime_error`
instead.  This is a so called ABI break.

Unfortunately, the standard library coming with g++ 5.x or 6.x doesn't
use the new C++11 ABI yet (apparently the change was just forgotten to
be made), but the code compiled with these compilers *does* use the
new ABI.  So when an exception is thrown from within the library it
has a different binary representation as expected by the compiled
application code.

This is fixed in g++ 7.  This is the [relevant bug
66145](https://gcc.gnu.org/bugzilla/show_bug.cgi?id=66145).  I've
stumbled over this issue while working with
[3DTK](https://sourceforge.net/p/slam6d/).  Relevant changes arround
[r1350](https://sourceforge.net/p/slam6d/code/1350/); patches from me
have been applied around that revision.
