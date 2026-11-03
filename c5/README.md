# ustreamer for the Creator 5

A static build of this ustreamer for the Creator 5's Ingenic X2600 (MIPS32r2, hard float, NaN 2008), made with Ingenic's `mips-xburst2-linux-toolchain-r6.0.0`. Being static, it needs no libraries on the printer. OpenCreator ships it as an experimental camera streamer, chosen in `camera.conf`.

## Build

```sh
c5/build.sh          # in WSL or Linux; INGENIC_TOOLCHAIN=... if the toolchain is elsewhere
```

The output is `c5/dist/ustreamer`. It builds ustreamer from this checkout, and downloads libevent 2.1.12 and IJG libjpeg 9f, checked against pinned SHA-256 sums. The libraries are built once into `$WORK` (`~/us-build`); `FRESH=1` builds them again. It needs `make`, `curl` and a C compiler only: no cmake or autotools.

`include/linux/` holds four V4L2 and media headers from the printer's 5.10 kernel, because the toolchain's are from 4.4 and lack the media API ustreamer uses. Their kernel-only markers (`linux/compiler.h` and `__user`) are removed, as the kernel's `headers_install` does.

GPIO, systemd, Janus, Python and process titles are off.

## Running it

The camera already compresses to MJPEG, so ustreamer passes its frames straight through with `--encoder=HW` instead of encoding them again. OpenCreator's `30-camera.sh` starts it like this, with the picture settings it otherwise sends to mjpg_streamer:

```sh
ustreamer --device=/dev/video0 --format=MJPEG --encoder=HW \
    --resolution=1280x720 --desired-fps=30 --host=0.0.0.0 --port=8080 \
    --allow-origin='*' --drop-same-frames=30 \
    --white-balance=4800 --saturation=100 --contrast=33 --hue=-20
```

It serves `/stream` and `/snapshot`, and mjpg_streamer's `/?action=stream` and `/?action=snapshot` too, so existing camera URLs keep working. Only one program can hold the camera.

## Licences

ustreamer is GPL-3.0, libevent BSD-3-Clause, and libjpeg under the IJG licence. The kernel headers are GPL-2.0 with the Linux syscall note.
