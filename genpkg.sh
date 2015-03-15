#!/bin/sh

CTRLFILE=$1


CURDIR=$PWD
SYMBOLSFILE=$CURDIR/keyboard/symbols/special
# TMPDIR=$(mktemp -d)
TMPDIR=testi
mkdir -p $TMPDIR

trap deinit INT TERM EXIT
deinit() {
    # rm -fr $TMPDIR
    :
}
die() { echo "Error: $@"; exit 1; }

# Generate include clauses inside the xkb configuration
generate_include() {
    for inc; do
        echo "	include \"$inc\""
    done
}

# Generate the default layout block of the xkb configuration
generate_layout_block() {
    local name="$(sed -n -e '/XKL-name:/{s/^[^:]*: //; p}' $CTRLFILE)"
    local includes="$(sed -n -e '/XKL-layouts:/{s/^[^:]*: //; p}' $CTRLFILE)"

    cat <<EOF
default partial alphanumeric_keys
xkb_symbols "$PKGNAME" {
	name[Group1]="$name";
EOF
    generate_include $includes

    echo "};"
}

test -z "$CTRLFILE" && { echo "Usage: $0 <control-file>" && exit 1; }
if ! test -f "$CTRLFILE"; then
    die "The control file is required for generating a package."
fi

(
    CTRLFILE=$(readlink -f "$CTRLFILE")
    PKGNAME=$(basename "$CTRLFILE")

    CMDLINE="$0 $@"
    VERSION=$(git describe --always)
    OUTFILE=usr/share/X11/xkb/symbols/$(basename "$CTRLFILE")
    LAYOUT=$(generate_layout_block)
    export TMPDIR CTRLFILE PKGNAME CMDLINE SYMBOLSFILE VERSION OUTFILE LAYOUT

    fakeroot /bin/sh -c "
cd $TMPDIR
mkdir -p DEBIAN
cat <<EOF > DEBIAN/control
$(cat $CTRLFILE)
EOF
mkdir -p $(dirname "$OUTFILE")
cat <<EOF > $OUTFILE
// Generated with $CMDLINE
// URL: https://github.com/kopoli/keyboard
// Version: $VERSION

EOF
cat <<EOF >> $OUTFILE
// The main layout
$LAYOUT

EOF

sed -n '/COLLECTIONS/q; p;' $SYMBOLSFILE >> $OUTFILE
cd $CURDIR
dpkg-deb -b $TMPDIR .
"
) || die "Building failed"
