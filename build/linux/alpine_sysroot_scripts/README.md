# Alpine Linux Sysroots

This directory contains a script for community contributed alpine linux sysroot support.

On Alpine Linux, run the script directly:

``` sh
./build/linux/alpine_sysroot_scripts/install-sysroot.sh
```

On other linux systems, you can run the script with Alpine Linux container:

``` sh
docker container run --rm \
                     --volume "$PWD:$PWD" \
                     --workdir "$PWD" \
                     docker.io/library/alpine \
                     ./build/linux/alpine_sysroot_scripts/install-sysroot.sh
```
