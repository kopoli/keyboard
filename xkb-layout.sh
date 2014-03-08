#!/bin/sh

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
	    echo invalid keymap: $map
	    echo "possibilities:  $mapconfigs"
	    echo current keymap: $(current_keymap)
	    exit 1
	fi
	;;
esac
