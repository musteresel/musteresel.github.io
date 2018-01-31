---
title: Gotcha with git worktree and removing the worktree directory
tags: git
date: 2018-01-31
language: en
...

[git worktree][worktree-man] is a very usefull feature of git which
allows for easy hotfixes and can even be used [for
deploying][deploy-post].  I just stumbled over a gotcha, though.

The man page says (emphasis mine):

> When you are done with a linked working tree you can simply delete
> it. The working tree’s administrative files in the repository [..]
> will **eventually** be removed automatically [..], or you can run
> `git worktree prune` in the main or any linked working tree to clean
> up any stale administrative files.

So, my expectation was that I can add a worktree, remove the
containing directory, and *if* it's then still in `git worktree list`
then just recreate the directory and continue my work:

```bash
git worktree add feature
git worktree list
# /tmp/repo          <COMMIT> [master]
# /tmp/repo/feature  <COMMIT> [feature]
rm -r feature
git worktree list
# /tmp/repo          <COMMIT> [master]
# /tmp/repo/feature  <COMMIT> [feature]
mkdir feature
touch feature/file
git worktree list
# /tmp/repo          <COMMIT> [master]
# /tmp/repo/feature  <COMMIT> [feature]
```

And indeed, the above output shows that git hasn't pruned (removed)
the feature worktree until now.  Changing into the `feature` directory
though reveals the truth:  git commands just act on the main
worktree.  And further commands...

```bash
git worktree prune
git worktree list
# /tmp/repo          <COMMIT> [master]
```

...show that the worktree is really gone.

Why is that?  Because the man page is a bit unclear: git doesn't
really care about the *directory*, but rather about a hidden file it
creates within said directory:

```bash
git worktree add new_feature
ls -a1 new_feature
# ...
# .git
# ...
```

Removing *this file* is what actually kills the worktree even before
the prune.  That file is though only mentioned shortly in the man
page:

> These settings are made in a `.git` file located at the top
> directory of the linked working tree.

A quick look at the contents of the `.git` shows which settings are in
there (note: there can be more than shown here):

```bash
gitdir: /tmp/repo/.git/worktrees/new_feature
```

So it's really the combination of keeping the path to the worktree and
the `.git` file within the worktree to keep the worktree alive.

You may ask how I could stumble over this?  Or rather why I would want
to remove the worktree directory.  The answer is: My `make clean`
command did just that ... `rm -r build/` (where `build/` is a git
worktree) ... because it was the simplest solution.

[worktree-man]: https://git-scm.com/docs/git-worktree
[deploy-post]: /posts/2018/01/git-worktree-for-deploying.html
