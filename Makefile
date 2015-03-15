
INSTDIR = $(HOME)/.local/share/applications
BINDIR ?= $(HOME)/softa/bin
RUNDIR  = $(PWD)

BIN_FILES=xkb-layout xkb-unlocker
DESKTOP_FILES=keylayout.desktop keyrotate.desktop

INST_FILE=install -m 0644
INST_EXEC=install -m 0755

FLAGS=-Wall -Wextra $(shell pkg-config --cflags --libs x11)

.SUFFIXES:
.SUFFIXES: .in .c

TARGETS=$(addprefix $(INSTDIR)/, $(DESKTOP_FILES)) $(addprefix $(BINDIR)/,$(BIN_FILES))
install: $(TARGETS)

clean:
	@$(RM) -v $(DESKTOP_FILES) $(BIN_FILES)

uninstall:
	@$(RM) -v $(TARGETS)

$(BINDIR)/%: %
	$(INST_EXEC) $< $@

$(INSTDIR)/%: %
	$(INST_FILE) $< $@

%:: %.in
	sed -e 's,@RUNDIR@,$(RUNDIR),g' $< > $@

%:: %.c
	$(CC) -o $@ $< $(FLAGS)

image:
	for s in $$(seq 1 3); do xkbprint -color -ll $$s  -fit :0 -lc en_US.ISO8859-15  -o -; done | ps2pdf - - > keyboard.pdf

pkg:
	for control in packages/*; do ./genpkg.sh $$control || exit 1; done
