#!/bin/sh

map="$1"

defmap=fi-qwerty

enable_switch_hyper_control()
{
    # this script sets hyper as the new control_l and moves control_l to capslock
    cat <<EOF | xmodmap -
! remove caps lock
clear lock

!remove hyper from super equivalency and control temporarily
remove mod4 = Hyper_L
remove control = Control_L

!set control to caps lock
keycode 66 = Control_L

!set the control to hyper
keycode 37 = Hyper_L

!set hyper and control to their rightful place
add mod3 = Hyper_L
add control = Control_L

EOF

    # take repeat away from the new control button
    xset -r 66
}

replace_capslock_hyper()
{
    cat <<EOF | xmodmap -
clear lock
remove mod4 = Hyper_L
add mod3 = Hyper_L
keycode 66 = Hyper_L
EOF
    #for some reason this has to be done afterwards
    xmodmap -e 'remove control = Hyper_L'

    xset -r 66
}

basedir=$(dirname $0)

test -z "$map" && map=$defmap

case $map in

    fi-qwerty|fi-das)
	KBDIR=$basedir/keyboard
	test -d "$KBDIR" || { echo "directory $KBDIR not found"; exit 1; }
	xkbcomp -I$KBDIR $KBDIR/${map}-layout.xkb $DISPLAY -w0

	xset r rate 200
	;;

    dvorak)
	# This has the level3 enabled with alt gr
	setxkbmap "us(dvorak-alt-intl)"

	cat <<EOF | xmodmap -

keycode  38 = a A a A adiaeresis Adiaeresis
keycode  39 = o O o O odiaeresis Odiaeresis

EOF

	;;
    *)
	echo invalid keymap $map
	exit 1
	;;
esac

#enable this when lower left control starts to get old
#enable_switch_hyper_control

replace_capslock_hyper
