# Alpine Linux Sysroots

This directory contains a script for community contributed alpine linux sysroot support.

On Alpine Linux, run the script directly:

``` sh
./build/linux/alpine_sysroot_scripts/install-sysroot.sh
```

By default, the script installs sysroots for the following architectures:

- `aarch64`
- `armv7`
- `x86_64`
- `x86`

To install sysroots for specific architectures, you can run:

``` sh
./build/linux/alpine_sysroot_scripts/install-sysroot.sh aarch64 riscv64 x86_64 ...
```

On other linux systems, you can run the script with Alpine Linux container:

``` sh
docker container run --rm \
                     --volume "$PWD:$PWD" \
                     --workdir "$PWD" \
                     docker.io/library/alpine \
                     ./build/linux/alpine_sysroot_scripts/install-sysroot.sh
```
