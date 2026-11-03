#!/bin/bash
# Builds a static ustreamer from this checkout for the Creator 5 (Ingenic X2600) with
# Ingenic's toolchain. See README.md. Output: c5/dist/ustreamer
set -e
cd "$(dirname "$0")"
HERE=$PWD
ROOT=$(cd .. && pwd)
TOOLCHAIN=${INGENIC_TOOLCHAIN:-/mnt/h/Klipperstuffs/ingenic-mips-toolchain-r6.0.0/mips-xburst2-linux-toolchain-r6.0.0}
HOST=mips-xburst2-linux-gnu
WORK=${WORK:-$HOME/us-build}
PREFIX=$WORK/prefix
export PATH="$TOOLCHAIN/bin:/usr/bin:/bin"
export CC=$HOST-gcc AR=$HOST-ar RANLIB=$HOST-ranlib STRIP=$HOST-strip
OPT="-O2 -march=xburst2 -mtune=xburst2"

LIBEVENT=2.1.12-stable
JPEG=9f
fetch() {  # name url sha256
    [ -f "$WORK/src/$1" ] || curl -fsSL -o "$WORK/src/$1" "$2"
    echo "$3  $WORK/src/$1" | sha256sum -c --quiet -
}
mkdir -p "$WORK/src" "$PREFIX"
fetch libevent.tar.gz https://github.com/libevent/libevent/releases/download/release-$LIBEVENT/libevent-$LIBEVENT.tar.gz \
    92e6de1be9ec176428fd2367677e61ceffc2ee1cb119035037a27d346b0403bb
fetch jpeg.tar.gz https://www.ijg.org/files/jpegsrc.v$JPEG.tar.gz \
    04705c110cb2469caa79fb71fba3d7bf834914706e9641a4589485c1f832565b

cd "$WORK"
# the libraries take a while: they're built once, FRESH=1 builds them again
if [ -n "$FRESH" ] || [ ! -f "$PREFIX/lib/libjpeg.a" ] || [ ! -f "$PREFIX/lib/libevent_pthreads.a" ]; then
    rm -rf jpeg-$JPEG libevent-$LIBEVENT "$PREFIX"
    tar xzf src/jpeg.tar.gz
    tar xzf src/libevent.tar.gz
    (cd jpeg-$JPEG && CFLAGS="$OPT" ./configure --host=$HOST --prefix="$PREFIX" --disable-shared --enable-static >/dev/null \
        && make -j8 >/dev/null && make install >/dev/null)
    (cd libevent-$LIBEVENT && CFLAGS="$OPT" ./configure --host=$HOST --prefix="$PREFIX" --disable-shared --enable-static \
        --disable-openssl --disable-samples --disable-libevent-regress --disable-debug-mode >/dev/null \
        && make -j8 >/dev/null && make install >/dev/null)
fi

# Built from a copy, so the checkout keeps no objects. GPIO, systemd, Janus, Python
# and setproctitle are off by default. include/ holds the printer kernel's (5.10)
# V4L2 and media headers: the toolchain's are from 4.4.
rm -rf ustreamer-src
cp -r "$ROOT/src" ustreamer-src
rm -rf ustreamer-src/build
make -C ustreamer-src -j8 ustreamer.bin \
    CC=$CC CFLAGS="$OPT -I$HERE/include -I$PREFIX/include" LDFLAGS="-static -L$PREFIX/lib" >/dev/null

mkdir -p "$HERE/dist"
$STRIP -o "$HERE/dist/ustreamer" ustreamer-src/ustreamer.bin
ls -l "$HERE/dist/ustreamer"
