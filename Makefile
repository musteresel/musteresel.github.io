# Get the relative path from the current directory to the directory
# containing this Makefile.
path_to_this_makefile := $(dir $(lastword $(MAKEFILE_LIST)))


ifeq ($(abspath $(path_to_this_makefile)),$(abspath $(CURDIR)))
# Force an out-of-source build if the current directory is the source
# root directory (which contains this Makefile). Otherwise continue
# with the build.
include out-of-source.mk


else
# This is an out-of-source build, setup VPATH to point to the actual
# sources.
VPATH = $(path_to_this_makefile)


# List of all posts, with year/month and filename. Note that the posts
# must be specified in the correct order: by date.
POSTS = \
  2017/04/make-get-last-n-of-list.html \
  2017/04/shell-path-up.html \
  2017/05/g++-catch-std-ios_base-failure.html \
  2017/07/c++-swapping-done-right.html \
  2017/07/xen-vm-console-connection.html \
  2017/12/python-strings-are-no-sequences.html \
  2017/12/specify-correct-handling-return-values.html \
  2018/01/pandoc-project-relative-links.html \
  2018/01/git-worktree-for-deploying.html \
  2018/01/git-worktree-gotcha-removed-directory.html \
  2018/02/bash-specify-password-cmdline-argument-interactively.html \
  2018/02/vnc-ssh-tunnel-xen-vm.html \
  2018/02/xen-migrate-vdi-to-other-storage-repository.html \
  2018/03/cmake-phony-like-target-for-docs.html \
  2018/03/c++-lazy-template-instantiation.html \
  2018/03/exploit-hnap-security-flaw-dlink-dir-615.html


# Add the posts/ prefix to get paths to the post files.
POSTFILES = $(addprefix posts/,$(POSTS))


# Extract a list of YYYY/MM and YYYY from the list of posts. This is
# used to generate monthly and yearly post listings. Note that the
# list contains (lots of) duplicates.
path_to_words = $(subst /, ,$(post))
YEARSANDMONTHS = $(foreach post,$(POSTS),\
  $(word 1,$(path_to_words)) \
  $(word 1,$(path_to_words))/$(word 2,$(path_to_words)))
YEARSANDMONTHSLISTS = \
  $(addprefix posts/,$(addsuffix /index.html,$(YEARSANDMONTHS)))


# By default, build all sites: special sites, posts and listings
default: index.html about.html $(POSTFILES) $(YEARSANDMONTHSLISTS) \
         legal.html tags all-posts.html


# Meta target to build all tag index sites.
.PHONY: tags
tags:


# Shell command used to get the path back up from the target to the
# root of the build directory. This is used to specify the html base
# tag to make relative links work everywhere.
path_up = realpath -m --relative-to $(abspath $(dir $@)) $(CURDIR)
relative_links_filter = \
  --filter pandoc-project-relative-links \
  -M pathToProjectRoot=$(shell $(path_up))


# Append the list of the most recent posts after the content of the
# index page.
index.html: PANDOC_FLAGS=-A recent.html.in
index.html: recent.html.in

ADD_SUFFIX=-V "title-suffix=musteresel's blog"

ADD_POSTREF=-V postref=$@
index.html: ADD_POSTREF=
index.html: ADD_SUFFIX=
legal.html: ADD_POSTREF=
about.html: ADD_POSTREF=

# Build html files from markdown with pandoc
%.html: %.md template.html.in
	@mkdir -p $(dir $@)
	pandoc --template $(filter %template.html.in,$^) -o $@ $< \
	  $(PANDOC_FLAGS) \
	  $(relative_links_filter) \
	  $(ADD_POSTREF) $(ADD_SUFFIX)


# Use pandoc to create a link to the post, suitable for inclusion in
# one of the many post lists.
%.link: %.md extract-link.html.in
	@mkdir -p $(dir $@)
	pandoc --template $(filter %extract-link.html.in,$^) \
	  -V path=$(patsubst %.link,%.html,$@) -o $@.new $<
	cmp --silent $@ $@.new && rm $@.new || mv $@.new $@


# Use pandoc to extract the tags a post is tagged with from a post
# file.  Write the tags sorted to the file such that all-tags can be
# created by a simpler merge operation.
%.tags: %.md extract-tags.txt.in
	@mkdir -p $(dir $@)
	pandoc --template $(filter %extract-tags.txt.in,$^) \
	  $< | sort -u -o $@


# Merge .tags files of all posts (which contain a sorted list of
# tags), remove duplicates.
all-tags: $(POSTFILES:.html=.tags) Makefile
	sort -u -m $(filter %.tags,$^) -o $@.new
	cmp --silent $@ $@.new && rm $@.new || mv $@.new $@

# Create and include a makefile with rules and prerequisites for each
# tag.
tags.mk: all-tags Makefile
	while read tag; do \
	  printf "tags: posts/tagged/%s/index.html\n" $$tag; \
	  printf "posts/tagged/%s/index.html: TITLE=\"tagged: %s\"\n" $$tag $$tag; \
	  printf "posts/tagged/%s/index.links: " $$tag; \
	  files=$$(grep -lxF $$tag $(POSTFILES:.html=.tags)); \
	  for file in $${files}; do \
	    printf " %s.link" $${file%.tags}; \
	  done; \
	  echo; \
	done < $(filter %all-tags,$^) > $@
include tags.mk


# To create a list of posts, the links to all those posts are
# concatenated in the order in which they're specified.
%.links:
	@mkdir -p $(dir $@)
	cat $(filter %.link,$^) > $@


# Create and include a makefile with rules and prerequisites for each
# of the lists (YYYY.links and YYYY/MM.links)
links.mk: Makefile
	$(foreach ym,$(YEARSANDMONTHS),\
	  echo "posts/$(ym)/index.html: TITLE=$(ym)" >> $@; \
	  echo "posts/$(ym)/index.links: $(filter posts/$(ym)%, $(POSTFILES:.html=.link))" >> $@;)
include links.mk


# Create a html page with the list of posts from a collection of
# links.
%.html: %.links template.html.in
	mkdir -p $(dir $@)
	pandoc --template $(filter %template.html.in,$^) \
	  -f html -t html \
	  -o $@ $< -V title=$(TITLE) -V pagetitle=$(TITLE) \
	  $(relative_links_filter) $(ADD_SUFFIX)


# Get the last 5 words (posts) from POSTFILES
include $(path_to_this_makefile)/last-n.mk
most_recent_posts = $(call last-n,5,$(POSTFILES))
recent-wrong-order.links: $(most_recent_posts:.html=.link)
recent.links: recent-wrong-order.links
	tac $< > $@
recent.html.in: recent.links
	pandoc -f html -t html -o $@ $< $(relative_links_filter)


all-posts.html: TITLE="All posts, most recent first"
all-posts-wrong-order.links: $(POSTFILES:.html=.link)
all-posts.links: all-posts-wrong-order.links
	tac $< > $@


.PHONY: clean
clean:
	rm -rf $(CURDIR)/*


.PHONY: release
release: default
	git add .
	git commit -m "Build output of $(shell cd $(path_to_this_makefile); git log '--format=format:%H' sources-master -1)"

endif
