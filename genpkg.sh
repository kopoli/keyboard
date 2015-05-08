#!/bin/sh

# Creates a debian package from a specially crafted debian control file
usage() {
    cat <<EOF
Usage: $0 <control-file>
EOF
    exit 1
}


CTRLFILE=$1
CURDIR=$PWD
TMPDIR=$(mktemp -d)

trap deinit INT TERM EXIT
deinit() {
    rm -fr $TMPDIR
}
die() { echo "Error: $@"; exit 1; }

# Generate include clauses inside the xkb configuration
generate_include() {
    for inc; do
        echo "	include \"$inc\""
    done
}

# Parse headings of control-formatted file
parse_heading() {
    sed -n -e "/^$1:/{s/^[^:]*: //; p}" < "$CTRLFILE"
}

generate_files_block() {
    local files=$(parse_heading XKL-files)
}

# Generate the default layout block of the xkb configuration
generate_layout_block() {
    local name="$(parse_heading XKL-name)"
    local includes="$(parse_heading XKL-layouts)"

    cat <<EOF
default partial alphanumeric_keys
xkb_symbols "$PKGNAME" {
	name[Group1]="$name";
EOF
    generate_include $includes

    echo "};"
}

install_layout() {
    BASECTRLFILE=$(basename "$CTRLFILE")
    OUTSYMBOLSFILE=usr/share/X11/xkb/symbols/$BASECTRLFILE
    OUTRULESFILE=usr/share/X11/xkb/rules/evdev.xml.d/$BASECTRLFILE.xml
    LAYOUT=$(generate_layout_block)
    (
        # export TMPDIR CTRLFILE PKGNAME CMDLINE SYMBOLSFILE VERSION OUTSYMBOLSFILE OUTRULESFILE LAYOUT
        set -e
        cd $TMPDIR
        mkdir -p $(dirname "$OUTSYMBOLSFILE") $(dirname "$OUTRULESFILE")
        cat <<EOF > $OUTSYMBOLSFILE
// Generated with $CMDLINE
// URL: https://github.com/kopoli/keyboard
// Version: $VERSION

EOF
        cat <<EOF >> $OUTSYMBOLSFILE
// The main layout
$LAYOUT

EOF

        cat <<EOF > $OUTRULESFILE
     <!-- Generator: $CMDLINE
          Version:   $VERSION
          Package:   $PKGNAME
       -->
     <layout>
       <configItem>
         <name>$BASECTRLFILE</name>
         <shortDescription>$(parse_heading XKL-shortDescription)</shortDescription>
         <description>$(parse_heading XKL-name)</description>
         <languageList>
           <iso639Id>$(parse_heading XKL-langiso639Id)</iso639Id>
         </languageList>
       </configItem>
       <variantList/>
     </layout>
     <!--  End package $PKGNAME -->
EOF
cat $OUTRULESFILE

    )
    PACKAGE_HAS_CONTENTS=t
}


install_files() {
    FILEDIR=${CTRLFILE}-files
    for file in $INSTALLFILES; do
        echo $file
        fname=${file%%|*}
        dname=${file##*|}
        install -D ${FILEDIR}/$fname $TMPDIR/$dname/$fname || \
            die "Copying file $fname to package failed."
    done

    PACKAGE_HAS_CONTENTS=t
}

create_package() {
    (
        set -e
        cd $TMPDIR
        mkdir -p DEBIAN

        export CURDIR TMPDIR PKGNAME CMDLINE VERSION
        fakeroot  /bin/sh -ec "
cat <<EOF > DEBIAN/control
$(sed -e '/^XKL/d' < $CTRLFILE)
EOF

cd $TMPDIR
chown -R root.root *
cd $CURDIR
dpkg-deb -b $TMPDIR .
"
    ) || die "Creating the package failed."
}


test -z "$CTRLFILE" && usage
if ! test -f "$CTRLFILE"; then
    die "The control file is required for generating a package."
fi

set -x

CTRLFILE=$(readlink -f "$CTRLFILE")
PKGNAME=$(basename "$CTRLFILE")

SYMBOLSFILE=$CURDIR/$(parse_heading "XKL-data")
INSTALLFILES=$(parse_heading "XKL-files")
CMDLINE="$0 $@"
VERSION=$(git describe --always)
PACKAGE_HAS_CONTENTS=

test -r "$SYMBOLSFILE" || die "Symbols file $SYMBOLSFILE not readable."

test -r "$SYMBOLSFILE" && install_layout
test -n "$INSTALLFILES" && install_files
test -n "$PACKAGE_HAS_CONTENTS" && create_package

