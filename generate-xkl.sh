#!/bin/sh

usage() {
    cat <<EOF
Usage: $0 <keymap-name> [auto-repeat-rate]

Generates a script "$NAME" which is a shorthand to setting your wanted
keyboard layout. The generated script can then be copied into \$PATH.

Arguments:
  <keymap-name>       - Name of the keymap as given to ${SETTER}.
  [auto-repeat-rate]  - Quoted pair of delay and rate as given to $XSET program.

EOF
    exit 1
}

NAME=xkl
SETTER=./xkb-layout.sh
XSET=xset
VERSION=$(git describe --always)

generate() {
    cat <<EOF > $NAME
#!/bin/sh
# Generated with: $CMDLINE
# URL: https://github.com/kopoli/keyboard
# Generator version: $VERSION

cd $PWD
$SETTER $MAP

EOF
    chmod a+x $NAME
}

MAP="$1"
REPEAT="$2"
CMDLINE="$0 $@"

test -z "$MAP" && usage
test -n "$REPEAT" && SETTER="XKB_RATE=\"$REPEAT\" $SETTER"

generate
