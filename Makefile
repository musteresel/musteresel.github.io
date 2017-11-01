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
POSTS = 2017/03/a-simple-test.html


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
         legal.html


# Shell command used to get the path back up from the target to the
# root of the build directory. This is used to specify the html base
# tag to make relative links work everywhere.
path_up = realpath -m --relative-to $(abspath $(dir $@)) $(CURDIR)


# Append the list of the most recent posts after the content of the
# index page.
index.html: PANDOC_FLAGS=-A recent.links
index.html: recent.links


# Build html files from markdown with pandoc
%.html: %.md template.html.in
	@mkdir -p $(dir $@)
	pandoc --template $(filter %template.html.in,$^) -o $@ $< \
	  -V htmlbase=$(shell $(path_up)) $(PANDOC_FLAGS)


# Use pandoc to create a link to the post, suitable for inclusion in
# one of the many post lists.
%.link: %.md extract-link.html.in
	@mkdir -p $(dir $@)
	pandoc --template $(filter %extract-link.html.in,$^) \
	  -V path=$(patsubst %.link,%.html,$@) -o $@ $<


# To create a list of posts, the links to all those posts are
# concatenated in the order in which they're specified.
%.links:
	@mkdir -p $(dir $@)
	cat $(filter %.link,$^) > $@


# Create and include a makefile with rules and prerequisites for each
# of the lists (YYYY.links and YYYY/MM.links)
links.mk: Makefile
	$(foreach ym,$(YEARSANDMONTHS),\
	  echo "posts/$(ym)/index.links: $(filter posts/$(ym)%, $(POSTFILES:.html=.link))" >> $@;)
include links.mk


# Create a html page with the list of posts from a collection of
# links.
%.html: %.links template.html.in
	mkdir -p $(dir $@)
	pandoc --template $(filter %template.html.in,$^) \
	  -f html -t html \
	  -o $@ $< -V title=INDEX -V pagetitle=INDEX \
	  -V htmlbase=$(shell $(path_up))


# Get the last 5 words (posts) from POSTFILES
include $(path_to_this_makefile)/last-n.mk
most_recent_posts = $(call last-n,5,$(POSTFILES))
recent-wrong-order.links: $(most_recent_posts:.html=.link)
recent.links: recent-wrong-order.links
	tac $< > $@


.PHONY: clean
clean:
	rm -rf $(CURDIR)/*


endif
