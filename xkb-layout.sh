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
usage: $0 [-rotate | keymap-name]

Changes the keyboard layout.

Arguments:

  -rotate        - This will rotate the keymaps in the following order:kl
                   $rotation
  <keymap-name>  - This will set to given keymap.

Without arguments it will set the keymap: $defmap

The following are possible keymaps: $mapconfigs
Current keymap: $(current_keymap)

EOF
    exit 1
}

map="$1"

defmap=fi-hs-qwerty

rotation="$defmap us-hs-dvorak $defmap"

basedir=$(dirname $0)
KBDIR=$basedir/keyboard

test -z "$map" && map=$defmap

mapconfigs=$(echo $KBDIR/*xkb | sed -e "s,$KBDIR/,,g; s,-layout.xkb,,g; s, ,|,g")

# display keymap in a layout file
layout_keymap()
{
    sed -ne '/xkb_symbols/{s,.*"\([^"]*\)".*,\1,; p; q;}' $1
}

# display currently used keymap
current_keymap()
{
    xkbprint $DISPLAY -o - | sed -ne '/Layout/{s,.*out: ,,; s,) cent.*,,; p;q}'
}

# display layout file
layout_file()
{
    echo $KBDIR/$1-layout.xkb
}

# set keyboard map from a layout file
set_keymap()
{
    xkbcomp -I$KBDIR $(layout_file $1) $DISPLAY -w0
    xset r rate 300 20
    xkb-unlocker

    notify-send -i info "Keymap set: $1"
}

# rotate keyboard maps
rotate_maps()
{
    kmap=$(current_keymap)

    next=
    for name in $rotation; do
	test -n "$next" && { next=$name; break; }
	test "$(layout_keymap $(layout_file $name))" = "$kmap" && next=1
    done

    test -z "$next" && next=$defmap
    set_keymap $next
}

case $map in

    dvorak)
	# This has the level3 enabled with alt gr
	setxkbmap "us(dvorak-alt-intl)"

	cat <<EOF | xmodmap -

keycode  38 = a A a A adiaeresis Adiaeresis
keycode  39 = o O o O odiaeresis Odiaeresis

EOF

	;;

    -rotate)
	rotate_maps
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
