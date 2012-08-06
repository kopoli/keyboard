#!/bin/sh

map="$1"

defmap=fi-hs-qwerty

basedir=$(dirname $0)
KBDIR=$basedir/keyboard

test -z "$map" && map=$defmap

mapconfigs=$(echo $KBDIR/*xkb | sed -e "s,$KBDIR/,,g; s,-layout.xkb,,g; s, ,|,g")

case $map in

    dvorak)
	# This has the level3 enabled with alt gr
	setxkbmap "us(dvorak-alt-intl)"

	cat <<EOF | xmodmap -

keycode  38 = a A a A adiaeresis Adiaeresis
keycode  39 = o O o O odiaeresis Odiaeresis

EOF

	;;
    *)
	mapfile=$KBDIR/${map}-layout.xkb
	if test -f $mapfile; then
	    xkbcomp -I$KBDIR $KBDIR/${map}-layout.xkb $DISPLAY -w0
	    xset r rate 200
	else
	    echo invalid keymap $map
	    exit 1
	fi
	;;
esac
