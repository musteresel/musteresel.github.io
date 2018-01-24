---
title: Get the last N items of a list with make
date: 2017-04-05
language: en
tags: make
---

While writing the Makefile which builds this blog I stumbled over an
unexpected issue: In order to create the list of the most recent posts
I had to get the last `N` items of the list of posts (which are
ordered by date, most recent last).

GNU make provides the function `wordlist` which returns a sublist of
some list, given the start index (counting from 1) and the end index
(inclusive). Further, the function `words` counts the items in a
list. So the straightforward solution is the following:

```makefile
last_N = $(wordlist $(substract $(words $(list)), \
                                $(substract $(N), 1)), \
                    $(words $(list)), \
                    $(list))
```

Assuming `L` is the length of the list, just take the items starting
from index `L - (N - 1)` (subtracting one is necessary due to 1 based
indices) up to index `L` and... *done?*

**Unfortunately not!** Simply because there's no `substract`
function. In fact, GNU make does not support any arithmetic at
all. Sure, you can call the shell or some other external program like
`expr` or `bc`, but both requires forking (and of course the presence
of said external program).

With the following approach I "circumvent" the required arithmetic
(actually it's more like using Peano arithmetic):

```makefile
last_N = $(wordlist $(words $(wordlist $(N), \
                                       $(words $(list)), \
                                       $(list))), \
                    $(words $(list)), \
                    $(list))
```

The trick is that in order to compute the start index I can count the
number of items in a list which has `N - 1` elements less than the
list I'm working on. Since the contents of this "counting list" are of
no importance, I just use the original list but leave out the *first*
`N - 1` items:

```makefile
# Example with N = 3
# 1 2 3 4 5 6 7  original list
#    /    .  /
#   /     . / -- leave out the first two items
#  /      ./
# 3 4 5 6 7      "counting list"
#         |
#         | -- 5 items, thus start index 5,
#         |    taken from original list
#         v
#         5 6 7  result list
```

Now this works fine, except for the case when there are less than `N`
items in the list. The "counting list" will then be empty, `words`
thus returns `0` which is not a valid start index to `wordlist`.

To guard against this case I check whether the list has an item at
index `N` (remember, counting from 1). If not, I just use the complete
list as result. Packing it up in nice function like variables:


```makefile
# Get the last N items of the (long enough!) list.
#
# Returns a list with the last N items of the given LIST. The given
# LIST must be long enough: it must contain at least N items.
#
# Note: For long lists double expansion of $(words $(2)) should
# probably be avoided; refactor to use a helper function which gets
# passed N, the LIST and the result of $(words $(2)).
#
# result = $(call last-n-unsafe, N, LIST)
last-n-unsafe = \
  $(wordlist $(words $(wordlist $(1), $(words $(2)), $(2))), \
             $(words $(2)), \
             $(2))


# Get the last N items of the list.
#
# Returns a list with the last N items of the given LIST. If the given
# LIST contains less than N items, the complete LIST is returned.
#
# result = $(call last-n, N, LIST)
last-n = \
  $(if $(word $(1), $(2)), \
       $(call last-n-unsafe, $(1), $(2)), \
       $(2))
```

I've put above [code into a gist][gist] so that you can easily use it if you
want.

Sure, it's a lot more hacky and less clear than just calling the shell
with an arithemtic expression. But hey, at least I didn't go as far as
to [completely implement arithmetic functions.][make_arithmetic] ;)



[make_arithmetic]: https://www.cmcrossroads.com/article/learning-gnu-make-functions-arithmetic
[gist]: https://gist.github.com/musteresel/1e287ae4c67e1c97433b7664686b9649
