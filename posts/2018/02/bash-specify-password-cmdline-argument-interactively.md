---
title: Specify a password command line argument interactively in Bash
tags: bash
date: 2018-02-04
language: en
...

Today I had to download a file to a server I was connected to via ssh:

```bash
wget https://some.website.com/file.zip
# ...
# HTTP request sent, awaiting response... 401 Unauthorized
# 
# Username/Password Authentication Failed.
```

The server I was running this on isn't "mine" and thus cannot be
trusted, thus I didn't want to just specify `--user=USERNAME` and
`--password=PASSWORD` on the command line as it would end up in at
least the bash history and possibly other places, from where I'd need
to delete it.

A IMO better way is to specify username and password interactively to
the shell, using the [`read`
builtin](https://www.gnu.org/software/bash/manual/bash.html#index-read):

```bash
wget https://some.website.com/file.zip \
  --user=`read -p 'username:'; echo $REPLY` \
  --password=`read -s -p 'password'; echo $REPLY`
```

[Command substitution](http://tldp.org/LDP/abs/html/commandsub.html)
(the backticks around the command) invokes a subshell, in which the
`read` is performed.  `read` assigns the input to the variable
`REPLY`, which I echo to standard output such that the invoking shell
substitutes the command with this output.
