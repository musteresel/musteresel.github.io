---
title: Shouldn't I specify correct handling of return values to the compiler?
tags: [c, c++, programming-language-theory]
date: 2017-12-27
language: en
...

Have you ever seen something like the following?  Do you immediately
see the issue?

```c
// ...
if (size < necessary_size) {
  size = size * 2;
  buffer = realloc(buffer, size);
  if (buffer == NULL) {
    // out of memory, sorry
    // some kind of error handling / logging
  }
}
// ...
```

This is a memory leak, because the memory `buffer` originally pointed
to cannot be freed when `realloc` fails.  There's no pointer pointing
to it anymore, after all.

I'll try to formulate rules which - when followed - would make the
above error impossible to occur:

 1. The pointer passed in as first argument must not be a temporary.
 2. The returned pointer must not be assigned to the pointer which was
    passed as first argument.
    
Of course I can add such rules to the documentation of the `realloc`
function, but - sadly - that won't really help.  People just don't
always read documentations.  Or they forget what they read.  Thus it
would be much better if I could *specify these rules such that the
compiler understands* and **enforces** them.

In C++ I can acutally express rule 1, at least somewhat:

```c++
using void_p = void *
void * foo(void_p &) {
  // stuff
  return NULL;
}
```

If I now try to use `foo` with a temporary, then the compiler will
bark:

```
error: invalid initialization of non-const reference of type 'void*&' from an rvalue of type 'void*'
```

A drawback here is that this only works with non-const references
... and as such allows me to do nasty things:

```c++
void * foo(void_p & x) {
  x = NULL; // there goes your pointer, HA!
  // stuff
  return NULL;
}
```

But, for rule 2, there's no real way of telling the compiler what is
allowed and what isn't.  I think, though, that a feature like this
could turn out really helpfull.  A completely blue-eyed take:

```c++
auto passed_pointer = $function.arguments()[0].source_variable();
if (passed_pointer.aliases().size() == 0
    && $function.return_value().assigned_to(only_pointer)) {
  compiler.fail("Return value overwrites only available pointer to"
                " previously allocated memory!");
}
```

The syntax for this thought experiment is borrowed from the
[metaclasses proposal for C++][metaclasses] (if you haven't read about
this, please do now!  It's an excellent idea).  The example above
though also shows why implementing such a feature could turn out to be
somewhere between hard and impossible:

```c++
void baz(void **pointer_var, void *  buffer) {
  *pointer_var = foo(buffer);
}

void bar() {
  void *pointers[] = {NULL, malloc(10), NULL};
  // imagine reliable error handling here
  int index = rand() % 3;
  baz(pointers + index, pointers + 1);
}
```

Inside of `baz`, there's the parameter `buffer` which is a pointer to
the allocated memory.  It doesn't get assigned, to.  Thus everything
seems fine.  Until I leave `baz`.  Do I now have a pointer to the
allocated memory or not?  This depends on the *runtime* value returned
by `rand()`.  Should the compiler be able to deal with such
situations?  Can it even?  Or will this turn out to be a (another)
lost case against the halting problem?

Instead of giving the compiler *rules to enforce* - which leads to a
conservative behaviour ... if it cannot be sure that the rules are
adhered to, then it's an error - it could be easier to give the
compiler *patterns for common errors*.  These could be handled more
permissive: If it cannot match the situation to any of the patterns,
then it assumes that everything is fine.  Only if a pattern that's
*known* to lead to an error is found, then issue an error.

```c++
if ($function.arguments()[0].source_variable()
    == $function.return_value().target_variable()) {
  compiler.fail("Looks like you're assigning the return value to the"
                " same variable which you also used as first"
                " argument; that's a bad idea!");
}
```

This could also catch simpler issues, for example when the return
value is not checked against "special" values (like `NULL`) inside the
calling function and also not passed to any other function nor
returned from the calling function:

```c++
void f(Cache & cache) {
  char * b = cache.get_buffer(); // assume this could return nullptr
  char c;
  std::cin >> c;
  b[0] = c;
}
```

This could then also catch issues like [this one I found in
uzbl][uzbl-issue] where [`g_io_channel_write_chars`][gio-fn] was used
but the special return value `G_IO_STATUS_AGAIN` (which indicates that
the function should be called again ... due to a non blocking socket
not being ready, for example) wasn't handled in any way.

**But is this really the job of the compiler? Shouldn't this be some
kind of code analysis tool?**  I think in the end, this wouldn't
matter.  Type checking is also some kind of code analysis.  It's part
of the compiler.  Style checking is another kind of code analysis.
It's most often not part of a compiler but a separate tool.

Actually, I think there *are* already tools capable of finding errors
like the ones I presented here.  But I think the most important issue
with these tools is that they have some kind of a database of "known
error-prone patterns".  This database is continuously extended by the
users of the analysis tool.  **It would be better if the developer
writing a function could specify the correct handling of its return
values in a standardized way, directly next to the function itself.**

[metaclasses]: https://www.fluentcpp.com/2017/08/04/metaclasses-cpp-summary/
[uzbl-issue]: https://github.com/uzbl/uzbl/issues/393
[gio-fn]: https://developer.gnome.org/glib/stable/glib-IO-Channels.html#g-io-channel-write-chars
