---
title: Python strings are no sequences
tags: python
date: 2017-12-07
language: en
...

I have a strong C / C++ background.  Thus, a "string" for me is a
*sequence of characters*.  Normally, there are operations to access an
individual element of such a sequence.  For C strings, that's
`str[i]` which is just a nice way to hide pointer arithmetic
(`str + i` and `i + str` and also `i[str]` are equivalent ways of
saying the same thing).  In C++, there's an `operator[]`.

The semantic I expect from these operations - *get an individual
element of a sequence* - could be expressed by the following Haskell
type signature:

```haskell
getSomeElement :: [a] -> a
```

In natural language: Given a sequence of things of type `a`, when
accessing an individual element, we get a thing of type `a`.

**Fair enough.**

Python also has "sequence-like" data types.  Lists.  Tuples.

```python
l = [1, 2, 3, 4] # a list of integers
l[1] # gives 2, an integer

t = (5, 6, 7, 8) # a tuple with integers
t[2] # gives 7, an integer
```

**But strings are different:**

```python
s = "help"
type(s) # <class 'str'> ... seems legit
s[0] # "h" ... huh? Isn't this ...
type(s[0]) # <class 'str'> ... a STRING, too?!?!
```

Does this hurt in practice?  I doubt it.  But I stumbled over it when
I tested the prototype of an algorithm I wrote: Initially, I was only
using strings as test input.  The algorithm uses expressions like
`data[index]` a lot - which in the case of strings returns new strings
of length one.  Thus, calling `len(data[index])` was returning `1`.
When I changed the input to lists of integers, `len(data[index])` was
then of course failing.  I had to rewrite each `data[index]` into
`data[index:index + 1]`.
