---
title: Project-relative links with Pandoc
tags: [blog, web]
date: 2018-01-10
language: en
...

I don't want to write something like `../../../posts/foo/bar.html`
when linking from one blog post to another.  A link like that would
need to be changed when either the target (`bar.html`) or the starting
post moved to another location.

IMO it's far more convenient to just write `posts/foo/bar.html`.  This
URL should be interpreted as relative with regard to the root
directory of the blog / project.

Initially I abused the HTML `<base>` tag for this.  Adding

```html
<base href="../../../">
```

to the head of a HTML page makes the browser prefix relative links
like the above `posts/foo/bar.html` with the URL given in the `href`
attribute (`../../../` in this case).

This worked out pretty well at first.  Or, at least until I needed a
*real* relative link (as in relative to the current page).  This is
especially annoying because this

```html
<a href="#section">Go to some section</a>
```

is *also* a relative link.  So with the above `<base>` tag, that link
points to `../../../#section`.

**This is extremely inconvenient!**  Thus I wrote a filter for Pandoc
to turn absolute URLs (file paths, rather) into links relative to the
project root.  It leaves relative links like `appendix/data.txt` or
`#section` unchanged and rather turns absolute file paths
(`/posts/foo/bar.html`) into links relative to the project root by
prefixing them with a given `pathToProjectRoot`.

You can find the [filter on Github][gh].  It's written in Haskell.
Contributions are welcome!

[gh]: https://github.com/musteresel/pandoc-project-relative-links


Running

```bash
pandoc -t markdown -i in.md \
  --filter pandoc-project-relative-links \
  -M pathToProjectRoot=../../..
```

turns an `in.md` like

```Markdown
This is a [relative link](relative/link.html) and this a [project
relative link](/project/relative.html).  [This](#thing) is also
relative.
```

into

```Markdown
This is a [relative link](relative/link.html) and this a [project
relative link](../../../project/relative.html). [This](#thing) is also
relative.
```

The meta variable `pathToProjectRoot` can also be specified in the
yaml front matter or any yaml files, of course.  And even if you don't
use Pandoc to create your webpages, you still can make use the filter,
because Pandoc can also "convert" HTML to HTML.
