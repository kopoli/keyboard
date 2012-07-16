
INSTDIR=$(HOME)/.local/share/applications
RUNDIR=$(PWD)

DESKTOP_FILES=keylayout.desktop

install: $(addprefix $(INSTDIR)/, $(DESKTOP_FILES))

clean: $(DESKTOP_FILES)
	rm -f $^

%: %.in
	sed -e 's,@RUNDIR@,$(RUNDIR),g' $< > $@

$(INSTDIR)/%: %
	cp $< $@
