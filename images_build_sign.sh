#!/bin/sh
if [ $# -eq 0 -o "-h" = "$1" -o "-help" = "$1" -o "--help" = "$1" ]; then
cat <<EOHELP
Usage: $0 <secret> <manifest>
sign.sh adds lines to a manifest to indicate the approval
of the integrity of the firmware as required for automated
updates. The first argument <secret> references a file harboring
the private key of a public-private key pair of a developer
that referenced by its public key in the site configuration.
The second argument <manifest> define the type of images
like 'stable', 'testing' or 'experimental'.

The script may be performed multiple times to the same document
to indicate an approval by multiple developers.

! This file is defined for file 'secret' and manifest of 'experimental' !
EOHELP
exit 1
fi
SECRET="secret" #$1  fix die VAR gesetzt
manifest="images/sysupgrade/$manifest.manifest" #$2   fix die VAR gesetzt
upper=$(mktemp)
lower=$(mktemp)
awk "BEGIN { sep=0 }
/^---\$/ { sep=1; next }
{ if(sep==0) print > \"$upper\";
else print > \"$lower\"}" \
$manifest

# Code von mir für ein autom. Update
git pull # holt Updates von Gluon per GIT
make update # aktualisierte die Sourcen
make clean # macht grob sauber
make dirclean # macht alles vor der Erstellung sauber
make -j6 GLUON_BRANCH=$manifest # Baut die Images aus den Sourcen
make -j6 GLUON_BRANCH=$manifest GLUON_TARGET=mpc85xx-generic # Baut auch TL WDR 4900 Image
make manifest GLUON_BRANCH=$manifest  #erzeugt manifest

./contrib/ecdsasign $upper < $SECRET >> $lower
cat $upper > $manifest
echo --- >> $manifest
cat $lower >> $manifest
rm -f $upper $lower
cp -a images /DATEN/BT-Sync/ffnl-sync/
