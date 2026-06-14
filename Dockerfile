ARG FUSE_VERSION=3.18.2

FROM alpine:3.24 AS builder
ARG FUSE_VERSION
RUN apk add --no-cache build-base meson ninja pkgconf linux-headers curl tar
WORKDIR /build
RUN set -eux; \
    curl -fsSL -o libfuse.tar.gz \
        "https://github.com/libfuse/libfuse/releases/download/fuse-${FUSE_VERSION}/fuse-${FUSE_VERSION}.tar.gz"; \
    tar xf libfuse.tar.gz; \
    cd "fuse-${FUSE_VERSION}"; \
    CFLAGS='-static -Os' LDFLAGS='-static' meson setup b \
        --prefix=/usr \
        --buildtype=release \
        --default-library=static \
        -Dexamples=false \
        -Dtests=false \
        -Duseroot=false \
        -Dc_link_args=-static; \
    ninja -C b util/fusermount3; \
    install -d /out /out/licenses; \
    install -m 4755 -o 0 -g 0 b/util/fusermount3 /out/fusermount3; \
    # GPL-2.0 source-availability artifacts baked into the image.
    cp -a LICENSES/. /out/licenses/ 2>/dev/null || true; \
    for f in LICENSE LICENSE.md GPL2.txt LGPL2.txt COPYING; do \
        [ -f "${f}" ] && cp "${f}" /out/licenses/ || true; \
    done; \
    printf '%s\n' "${FUSE_VERSION}" > /out/VERSION

FROM busybox:1.38-musl
COPY --from=builder /out/fusermount3 /fusermount3
COPY --from=builder /out/licenses/ /licenses/
COPY --from=builder /out/VERSION /VERSION
COPY SOURCES.md /SOURCES.md
ENTRYPOINT ["/fusermount3"]
CMD ["--version"]
