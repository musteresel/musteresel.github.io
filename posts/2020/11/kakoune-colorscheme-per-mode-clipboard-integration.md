---
title: Kakoune change colorscheme with mode and clipboard integration
tags: [kakoune, linux, editor]
date: 2020-11-20
language: en
...

I'm currently trying out [Kakoune][] as editor instead of Emacs.  I won't go
into details about it - that's easily findable on its website - but will cut
straight to the point:  It is a modal editor, similar to Vim. So instead of
using key combinations during writing there is an "insert" mode, in which
one can insert text, and a "normal" mode, which is used for commands. (There are
more modes of course; but those two are the most important right now.)

An issue I always had with Vim is that I never know which mode I'm currently in.
People said I'd get used to it, but I didn't, so for Kakoune I wanted to make
sure I have a *strong* visual clue of the current mode.  Changing colorschemes -
especially from a dark to a light one - is a **pretty** strong visual clue:

~~~
hook global WinCreate '.*' %{
  colorscheme window-solarized-dark
  hook window ModeChange 'push:.*:insert' 'colorscheme window-solarized-light'
  hook window ModeChange 'push:insert:.*' 'colorscheme window-solarized-dark'
  hook window ModeChange 'pop:insert:.*' 'colorscheme window-solarized-dark'
  hook window ModeChange 'pop:.*:insert' 'colorscheme window-solarized-light'
}
~~~

This is a hook (with global scope) which executes on the creation of any window.
It sets a colorscheme "window-solarized-dark" (under the assumption that the
initial mode of a window is not insert mode) and then goes on to install 4
hooks in the scope of the just created window.  These hooks execute when there
is a mode change in the current window, and set a colorscheme
"window-solarized-light" whenever the mode is changed to insert mode.

Initially I thought 2 hooks would do: One for entering insert mode and one for
leaving insert mode.  But since modes in Kakoune are on a stack, you can enter
insert mode, then push a new mode on the stack (and thus temporarily switching
to that mode) and then pop back into insert mode.  That's why there's 4 cases,
in the same order as the hooks above:

- Push insert mode onto the stack.
- Push another mode onto the stack while in insert mode (and thus leaving insert
  mode).
- Pop insert mode from the stack, going to the previous mode. Note: I assume
  that this is *not* insert mode!
- Pop any other mode from the stack, going back to insert mode.

The last thing missing is the colorscheme: I couldn't just use any of the
provided colorschemes, because they have code like this:

~~~
face global Whitespace <some-color>
~~~

They set the *faces* in the *global* scope.  But I only want to change the
colorscheme in a single window, thus I changed the colorschemes (in my case the
solarized colorschemes which come by default with kakoune) to install the faces
in *window* scope:

~~~
face window Whitespace <some-color>
~~~

And then I have a very strong visual clue in which mode I'm in!

As an added bonus, here's how I integrated the clipboard into Kakoune:

~~~
define-command yank-clipboard %{
  execute-keys -draft '<a-|>xclip -in -selection clipboard >&- 2>&-<ret>'
}
define-command paste-clipboard %{
  execute-keys -draft '!xclip -out - -selection clipboard 0>&- 2>&-<ret>'
}
~~~

`yank-clipboard` pipes the (Kakoune) selection(s) to `xclip`, which reads from
stdin into the (X) selection "clipboard".  Additionally, due to how xclip works,
I close it's stderr and stdout.

`paste-clipboard` reads from the pipe connected to stdout of `xclip`, which
reads out of the (X) selection "clipboard".  To avoid xclip hanging I close its
stdin and stderr.

