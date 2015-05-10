#!/bin/sh

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

usage()
{
    test -n "$1" && echo "Error: $@"

    cat <<EOF
usage: $0 <keymap-name>

Changes the keyboard layout.

Arguments:
  <keymap-name>  - This will set to given keymap.

The following are possible keymaps:
  $(echo $KBDIR/*xkb | sed -e "s,$KBDIR/,,g; s,-layout.xkb,,g; s, ,\n  ,g")

The keymap and related files should be in directory: $KBDIR

Current keyboard layout (from X11): $(current_keymap)

EOF
    exit 1
}

def() { eval "$1=\${$1-\"$2\"}"; }

def KBDIR $PWD/keyboard
def XKB_RATE "300 20"

# display keymap in a layout file
layout_keymap() {
    sed -ne '/xkb_symbols/{s,.*"\([^"]*\)".*,\1,; p; q;}' $1
}

# display currently used keymap
current_keymap() {
    xkbprint $DISPLAY -o - | sed -ne '/Layout/{s,.*out: ,,; s,) cent.*,,; p;q}'
}

# display layout file
layout_file() {
    echo $KBDIR/$1-layout.xkb
}

# set keyboard map from a layout file
set_keymap() {
    xkbcomp -I$KBDIR $(layout_file $1) $DISPLAY -w0
    xset r rate $XKB_RATE
    xkb-unlocker

    notify-send -i info "Keymap set: $1"
}

# main script
map="$1"
case "$map" in
    '')
        usage
        ;;
    *)
	mapfile=$KBDIR/${map}-layout.xkb
	if test -f $mapfile; then
	    set_keymap ${map}
	    echo $(layout_keymap $mapfile)
	else
	    usage "invalid keymap: $map"
	fi
	;;
esac
