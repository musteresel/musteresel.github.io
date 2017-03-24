# Disable implicit suffix rules
.SUFFIXES:


OUTDIR := build


# Recurse into the subdirectory, re-execute make there to perform an
# out-of-source build.
.PHONY: $(OUTDIR)
$(OUTDIR):
	+@echo "FORCING OUT-OF-SOURCE BUILD IN $(OUTDIR)"
	+@[ -d $@ ] || mkdir -p $@
	+@$(MAKE) --no-print-directory -C $@ \
                  -f $(CURDIR)/Makefile \
                  $(MAKECMDGOALS)


# Guard against infinite self rebuild loop
Makefile : ;
%.mk :: ;


# Build any target by building the subdirectory (with the target)
# first. Then do nothing (as the target is already built in the
# subdirectory).
% :: $(OUTDIR) ; :


.PHONY: clean
clean:
	rm -rf $(OUTDIR)
