---
title: Swapping C++ objects done right
date: 2017-07-06
tags: c++
language: en
...

How to swap two objects?  For example in a sorting function which is
written as a template function so that it works for any type (which is
comparable and swappable).

The naive approach to swap `a` and `b` of type `T &` is:

```c++
T temporary = a;
a = b;
b = temporary;
```

But this means that `T` has to be copy constructible and copy
assignable.  These are pretty tough requirements, as it forces `T` to
have such a constructor and operator defined.  Moreover it creates a
probably superfluous copy.  One can possibly mitigate this later issue
by adding `std::move` and requiring move construction and move
assignment, but this still extremely limits the implementation of type
`T`.

*Use the standard library!* That's a good thought.  There's
`std::swap` after all, and it hopefully get's its job done, no?  Well,
*yes*.  It requires the type to be move assignable and move
constructible, just as above.  That's because it's (at least in the
GNU C++ library) [implemented][gnu-c++-swap] exactly like above
(factoring in the moves, of course).  But nonetheless, the following
is a *not* how one should swap two objects:

```c++
// Wrong!
std::swap(a, b);
```

This hard-codes `std::swap` as the function to use for swapping, and
thus forces the type `T` to (correctly) implement the constructor and
operator; even if they're not needed or reasonably practicable.

C++ also has a powerful (and sometimes confusing) mechanism to allow
multiple namespaces to be searched for a function: [argument dependent
lookup (ADL)][ADL].  This requires the function to be called via an
"unqualified name" (e.g. `foo` instead of `::foo` or `nspace::foo`)
and results in the compiler searching for `foo` not only in the
current scope but also in the namespaces in which the types of the
arguments of the function are defined.  Thus correct swapping is done
like this:

```c++
// Correct!
using std::swap;
swap(a, b);
```

In most cases, this will work exactly like the previous (wrong) code
snippet: The compiler will find `std::swap` which was brought into
scope with `using std::swap`.  The type has to implement the discussed
constructor and operator.  But if there's a reasonable implementation
to swap objects of the type `T`, then the developer implementing `T`
can write a *specialized* swap function in the same namespace in which
`T` is defined.  Calling `swap` (an unqualified name) will then invoke
ADL and find and use this specialized swap function:

```c++
namespace nspace {
  struct foo {};
  void swap(foo &, foo &);
}

// somewhere in the code
nspace::foo a = get_some_foo();
nspace::foo b = get_some_foo();
swap(a, b); // will call nspace::foo through ADL
```

Thus to correctly swap two objects one first brings `std::swap` into
scope as a kind of "fallback" (in case there's no specialized swap
function) and then calls `swap` unqualified, which enables ADL.


[ADL]: http://en.cppreference.com/w/cpp/language/adl
[gnu-c++-swap]: https://github.com/gcc-mirror/gcc/blob/gcc-7_3_0-release/libstdc%2B%2B-v3/include/bits/move.h#L198
