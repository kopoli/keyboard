
INSTDIR=$(HOME)/.local/share/applications
RUNDIR=$(PWD)

DESKTOP_FILES=keylayout.desktop

install: $(addprefix $(INSTDIR)/, $(DESKTOP_FILES))

clean: $(DESKTOP_FILES)
	rm -f $^

%: %.in
	sed -e 's,@RUNDIR@,$(RUNDIR),g' $< > $@

image:
	for s in $$(seq 1 3); do xkbprint -color -ll $$s  -fit :0 -lc en_US.ISO8859-15  -o -; done | ps2pdf - - > keyboard.pdf

$(INSTDIR)/%: %
	cp $< $@
