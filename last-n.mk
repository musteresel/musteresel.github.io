# Copyright 2017 Daniel Jour <musteresel@gmail.com>
#
# Permission is hereby granted, free of charge, to any person
# obtaining a copy of this software and associated documentation files
# (the "Software"), to deal in the Software without restriction,
# including without limitation the rights to use, copy, modify, merge,
# publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.


# last-n.mk
# --------------------------------------------------------------------
# This file contains an unsafe and a safe variant of a function to
# return the last N items of some list. It is written for GNU make.
# For updates, look here: https://gist.github.com/musteresel/1e287ae4c67e1c97433b7664686b9649
# --------------------------------------------------------------------


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
