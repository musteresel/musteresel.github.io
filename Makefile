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


default: index.html about.html posts/2017/03/a-simple-test.html


# Build html files from markdown with pandoc
%.html: %.md template.html
	mkdir -p $(dir $@)
	pandoc --template $(filter %template.html,$^) -o $@ $<


.PHONY: clean
clean:
	rm -rf $(CURDIR)/*

endif
