#!/usr/bin/env bash
### every exit != 0 fails the script
set -e

FF_VERS='45.9.0esr'
FF_INST='/usr/lib/firefox'

echo "Downloading Firefox $FF_VERS and install it to '$FF_INST'."
mkdir -p "$FF_INST"
FF_URL=http://releases.mozilla.org/pub/firefox/releases/$FF_VERS/linux-x86_64/en-US/firefox-$FF_VERS.tar.bz2
echo "FF_URL: $FF_URL"
wget -qO- $FF_URL | tar xvj --strip 1 -C $FF_INST/
ln -s "$FF_INST/firefox" /usr/bin/firefox
exit $?
