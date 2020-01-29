---
title: Examples of `br_table` in WebAssembly text
tags: webassembly
date: 2020-01-29
language: en
...

Somehow I found it surprisingly hard to find examples of how to use
the `br_table` instruction from WebAssembly text (`*.wat`) files.
Therefore I've written down a few examples here for reference:

~~~lisp
(func (export "nop")
  (i32.const 1)  ;; value used to select a branch
  (br_table 0)) ;; table branch with only a default branch
~~~

This is the simplest valid usage of `br_table`:  It specifies a
default branch target and nothing else.  So whatever value is on the
top of the stack; the `br_table` uses the default branch target (`0`
in this case).

~~~lisp
(func (export "early_exit") (result i32)
  (i32.const 21) ;; push some constant value to the stack, to be
                 ;; returned from the function
  (i32.const 0) ;; value used to select a branch
  (br_table 0) ;; table branch with only a default branch
               ;; default -> (br 0) ;; exits the function
  ;; code below here is never executed!
  (drop) 
  (i32.const 42)
   )
~~~

The example above shows that `br_table` does not create a branch
target on it's own.  Branch target `0` means the next outermost
structured block, which in this case is the entire function.
Therefore the `drop` and push of the 42 won't be executed; thus this
function returns 21.

This also shows that in order for a `br_table` to be useful (in the
sense that it may branch to different branch targets) it *has* to be
wrapped in at least one `block` (or `loop` etc).  There is no way to
continue *after* a `br_table` instruction.

A "switch" like construct will thus look like this:

~~~lisp
(func (export "switch_like") (param $p i32) (result i32)
  (block
    (block
      (block
        (block (get_local $p)
               (br_table
                         2   ;; p == 0 => (br 2)
                         1   ;; p == 1 => (br 1)
                         0   ;; p == 2 => (br 0)
                         3)) ;; else => (br 3)
        ;; Target for (br 0)
        (i32.const 100)
        (return))
      ;; Target for (br 1)
      (i32.const 101)
      (return))
    ;; Target for (br 2)
    (i32.const 102)
    (return))
  ;; Target for (br 3)
  (i32.const 103)
  (return))
~~~

This creates 4 nested `block`s to give the `br_table` 4 different
branch targets to jump to.  The last specified is the "default" branch
which is taken when the value on the stack is not an index into the
list of the branches.  Since jumping to a `block` means jumping to its
end the actual code for each of the branches follows the end of a more
nested `block`.  This also implies that in order to "leave" this
"switch like" construct another branch is necessary.  In this case I
took the easy route and just exited the function (branch to the
outermost block) via `(return)`. `switch_like(0)` will branch to
branch target `2` (after the third enclosing block of the `br_table`,
counted from inside to outside) and thus return 102.

A slightly more complex example, showing more jumping:

~~~lisp
(global $A (export "A") (mut i32) (i32.const 0))
(global $B (export "B") (mut i32) (i32.const 0))
(func (export "set") (param $select i32) (param $value i32)
  (block
    (block
      (get_local $select)
      (br_table 1 0 2)) ;; default (br 2) == (return)
    ;; Branch target 0 of br_table, used for select == 1
    (get_local $value)
    (set_global $A) ;; set A = value
    (get_local $value)
    (i32.const 42)
    (i32.eq)
    (br_if 0) ;; if value == 42, jump out of this block
    (return)) ;; else, return from function
  ;; Branch target 1 of br_table, used for select == 0
  ;; Branch target 0 of br_if, used if value == 42
  (get_local $value)
  (set_global $B)) ;; set B = value
~~~

- `set(0, 10)` sets `B = 10` and leaves `A` as it is
- `set(1, 20)` sets `A = 20` and leaves `B` as it is
- `set(2, 30)` does nothing
- `set(0, 42)` sets `B = 42` and leaves `A` as it is
- `set(1, 42)` sets `A = 42` and then also `B = 42`
