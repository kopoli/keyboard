
INSTDIR=$(HOME)/.local/share/applications
BINDIR=$(HOME)/softa/bin
RUNDIR=$(PWD)

BIN_FILES=xkb-layout
DESKTOP_FILES=keylayout.desktop keyrotate.desktop

install: $(addprefix $(INSTDIR)/, $(DESKTOP_FILES)) $(addprefix $(BINDIR)/,$(BIN_FILES))

clean: $(DESKTOP_FILES) $(BIN_FILES)
	$(RM) $^

%: %.in
	sed -e 's,@RUNDIR@,$(RUNDIR),g' $< > $@

image:
	for s in $$(seq 1 3); do xkbprint -color -ll $$s  -fit :0 -lc en_US.ISO8859-15  -o -; done | ps2pdf - - > keyboard.pdf

$(BINDIR)/%: %
	cp $< $@
	chmod a+x $@

$(INSTDIR)/%: %
	cp $< $@
