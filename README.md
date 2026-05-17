# fusermount3-static

A statically-linked `fusermount3` built from upstream [libfuse](https://github.com/libfuse/libfuse), distributed both as a raw binary and as a container image. The result has no dynamic library dependencies (no `NEEDED`, no `INTERP`) and runs on any Linux kernel that supports FUSE — regardless of the host's libc.

## Why

Minimal / immutable Linux distributions (Flatcar, Talos, Bottlerocket, distroless) ship the FUSE kernel module but **no userspace `fusermount` helper**. Anything that wants to set up a FUSE mount on the host — for example [Sysbox](https://github.com/nestybox/sysbox)'s `sysbox-fs` daemon — needs `fusermount3` to be present in `$PATH` and `setuid root`. Extracting it from a Debian or Ubuntu `fuse3` package works but couples the resulting binary to a specific glibc version, which is fragile across distro upgrades.

This repository produces a single static binary that you can drop into `/usr/bin/`, `/opt/bin/`, a sysext, or a Talos extension, with no further runtime dependencies.

## Artifacts

Each release publishes:

- **Container image** at `ghcr.io/<owner>/fusermount3-static:<version>` (multi-arch, `linux/amd64` + `linux/arm64`). Contains `/fusermount3` over a tiny `busybox:musl` base — small enough to use as either a Dockerfile build stage or a DaemonSet init container.
- **Raw binary** at `https://github.com/<owner>/fusermount3-static/releases/download/v<version>/fusermount3-<version>-linux-<arch>` for direct `curl | install` use.
- **`SHA256SUMS`** for both.

## Usage

### 1. Multi-stage Dockerfile (`COPY --from=`)

```dockerfile
FROM ghcr.io/till0196/fusermount3-static:3.18.2 AS fm
FROM your-base
COPY --from=fm /fusermount3 /usr/bin/fusermount3
RUN chmod 4755 /usr/bin/fusermount3
```

### 2. Direct download

```sh
curl -fsSL -o /usr/local/bin/fusermount3 \
  https://github.com/till0196/fusermount3-static/releases/download/v3.18.2/fusermount3-3.18.2-linux-amd64
echo "<sha256-from-SHA256SUMS>  /usr/local/bin/fusermount3" | sha256sum -c -
chmod 4755 /usr/local/bin/fusermount3
chown 0:0 /usr/local/bin/fusermount3
```

### 3. DaemonSet (install onto host)

```yaml
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: install-fusermount3
spec:
  selector: { matchLabels: { app: install-fusermount3 } }
  template:
    metadata: { labels: { app: install-fusermount3 } }
    spec:
      hostPID: true
      containers:
        - name: install
          image: ghcr.io/till0196/fusermount3-static:3.18.2
          command: ["/bin/sh", "-c"]
          args:
            - |
              install -m 4755 -o 0 -g 0 /fusermount3 /host/usr/bin/fusermount3
              # Re-exec PID 1 sleep so the pod stays Running; the kubelet
              # treats Completed pods as failed and restarts them.
              exec sleep infinity
          securityContext: { privileged: true }
          volumeMounts:
            - name: host-usrbin
              mountPath: /host/usr/bin
      volumes:
        - name: host-usrbin
          hostPath: { path: /usr/bin }
```

> On Flatcar `/usr/bin` is read-only — mount `/opt/bin` instead, and ensure consumers look there (`PATH=/opt/bin:$PATH` for the consuming process).

### 4. Flatcar systemd-sysext

The [`sysext-bakery`](https://github.com/flatcar/sysext-bakery) project ships a recipe that wraps this binary into a sysext `.raw` for Flatcar / Fedora CoreOS / Bottlerocket consumption.

### 5. Talos System Extension

Reference the image as a `FROM` stage when building the extension rootfs:

```dockerfile
FROM ghcr.io/till0196/fusermount3-static:3.18.2 AS fm
# ... extension build steps ...
COPY --from=fm /fusermount3 /rootfs/usr/bin/fusermount3
```

## Verification

The binary is fully static, with no dynamic linker:

```sh
$ readelf -d fusermount3
Dynamic section at offset 0x... contains 0 entries.

$ readelf -l fusermount3 | grep INTERP || echo "(no INTERP)"
(no INTERP)

$ ./fusermount3 --version
fusermount3 version: 3.18.2
```

## Licensing

`fusermount3` is part of [libfuse](https://github.com/libfuse/libfuse) and is licensed under **GPL-2.0-only**. The redistributed binary in this repository inherits that license; sources are available unmodified at the libfuse upstream tag matching the version you build.

The build scripts and packaging in this repository (`Dockerfile`, `.github/workflows/`, `README.md`) are released under the **MIT License**, see [`LICENSE`](./LICENSE).

## Releasing

Push a tag of the form `v<libfuse-version>` (e.g. `v3.18.2`) to trigger the release workflow, which builds the multi-arch image and uploads the raw binaries to the GitHub release.

```sh
git tag v3.18.2
git push origin v3.18.2
```

For ad-hoc builds without releasing, use the workflow's `workflow_dispatch` trigger — binaries land in run artifacts and the image is still pushed to GHCR.
