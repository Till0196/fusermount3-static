# Source availability (GPL-2.0 compliance)

This image and the binaries published in the corresponding GitHub release
contain the following components subject to GPL-2.0. Complete corresponding
source is available as described below.

## `fusermount3` — GPL-2.0-only

Built unmodified from the [libfuse](https://github.com/libfuse/libfuse)
project. The exact build version is recorded at `/VERSION` inside the image.

For each release of this repository, the matching libfuse source tarball is
bundled alongside the binaries as `libfuse-<version>.tar.gz`:

  https://github.com/till0196/fusermount3-static/releases

Upstream mirror:

  https://github.com/libfuse/libfuse/releases

## `busybox` — GPL-2.0-or-later

This image is based on `busybox:1.37-musl` (Docker official image). Source
for the busybox version inside the base image is available at:

  https://busybox.net/downloads/
  https://hub.docker.com/_/busybox  (image-level source pointer)

## `musl libc` — MIT (statically linked into `/fusermount3`)

Included for reference; no GPL compliance obligation. Source:

  https://musl.libc.org/releases/

## Written offer

In accordance with GPL-2.0 section 3(b), the maintainers will, on request,
provide complete corresponding source for any GPL-licensed component in any
released artifact, for a period of three years from the date of that release.
File an issue at https://github.com/till0196/fusermount3-static/issues to
request source.
