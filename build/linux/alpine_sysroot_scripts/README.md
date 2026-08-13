# Alpine Linux Sysroots

This directory contains a script for community contributed alpine linux sysroot support.

To build the dart-sdk on alpine linux, please checkout the community maintained project https://github.com/dart-musl/dart.

On Alpine Linux, run the script directly:

``` sh
./build/linux/alpine_sysroot_scripts/install-sysroot.sh
```

By default, the script installs sysroots for the following architectures:

- `aarch64`
- `armv7`
- `riscv64`
- `x86_64`

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
