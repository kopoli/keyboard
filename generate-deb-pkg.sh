#!/bin/sh

usage() {
    cat <<EOF
Usage: $0 <control-file>

Creates a debian package from a specially crafted debian control file. See
README.org for details.

EOF
    exit 1
}

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
    test -f "$SYMBOLSFILE" -a -r "$SYMBOLSFILE" || \
        die "Symbols file $SYMBOLSFILE not readable."

    BASECTRLFILE=$(basename "$CTRLFILE")
    OUTSYMBOLSFILE=usr/share/X11/xkb/symbols/$BASECTRLFILE
    OUTRULESFILE=usr/share/X11/xkb/rules/evdev.xml.d/$BASECTRLFILE.xml
    LAYOUT=$(generate_layout_block)
    (
        set -e
        cd $TMPDIR
        mkdir -p $(dirname "$OUTSYMBOLSFILE") $(dirname "$OUTRULESFILE")
        cat <<EOF > $OUTSYMBOLSFILE
// Generated with $CMDLINE
// URL: https://github.com/kopoli/keyboard
// Version: $VERSION

EOF

        cat <<EOF > $OUTRULESFILE
     <!-- Generator: $CMDLINE
          Version:   $VERSION
          Package:   $PKGNAME
       -->
EOF

        # The following might need a second expansion
        SHORTDESC=$(parse_heading XKL-shortDescription)
        DESC=$(parse_heading XKL-name)
        LANGID=$(parse_heading XKL-langiso639Id)

        export OUTSYMBOLSFILE PKGNAME OUTRULESFILE SHORTDESC DESC LANGID
        /bin/sh -c "
cat <<EOF >> $OUTSYMBOLSFILE
// The main layout
$LAYOUT

// Layout data:
EOF

cat <<EOF >> $OUTRULESFILE
     <layout>
       <configItem>
         <name>$BASECTRLFILE</name>
         <shortDescription>$SHORTDESC</shortDescription>
         <description>$DESC</description>
         <languageList>
           <iso639Id>$LANGID</iso639Id>
         </languageList>
       </configItem>
       <variantList/>
     </layout>
     <!--  End package $PKGNAME -->
EOF
"
        # Copy the XKL-data to the end of the layout file (Without the COLLECTIONS)
        sed -n -e '/COLLECTIONS/q; p' < $SYMBOLSFILE >> $OUTSYMBOLSFILE
    )
    PACKAGE_HAS_CONTENTS=t
}


install_files() {
    FILEDIR=${CTRLFILE}-files
    for file in $INSTALLFILES; do
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
cd $TMPDIR
cat <<EOF > DEBIAN/control
$(sed -e '/^XKL/d' < $CTRLFILE)
EOF

chown -R root.root *
cd $CURDIR
dpkg-deb -b $TMPDIR .
"
    ) || die "Creating the package failed."
}

# main script

CTRLFILE=$1
CURDIR=$PWD
TMPDIR=$(mktemp -d)

trap deinit INT TERM EXIT

test -z "$CTRLFILE" && usage
if ! test -f "$CTRLFILE"; then
    die "The control file is required for generating a package."
fi

CTRLFILE=$(readlink -f "$CTRLFILE")
PKGNAME=$(basename "$CTRLFILE")


test -f "$CTRLFILE" || die "$CTRLFILE must be a file."

SYMBOLSFILE=$CURDIR/$(parse_heading "XKL-data")
INSTALLFILES=$(parse_heading "XKL-files")
CMDLINE="$0 $@"
VERSION=$(git describe --always)
PACKAGE_HAS_CONTENTS=


test -f "$SYMBOLSFILE" && install_layout
test -n "$INSTALLFILES" && install_files
test -n "$PACKAGE_HAS_CONTENTS" && create_package

