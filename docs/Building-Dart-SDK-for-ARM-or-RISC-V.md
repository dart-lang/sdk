# Introduction

The Dart VM runs on a variety of ARM processors on Linux and Android. This document explains how to build the Dart VM and SDK to target these platforms.

# Cross-compiling

The build scripts download a Clang toolchain that can target IA32, X64, ARM, ARM64 or RISCV64 and run on an X64 or ARM64 host. For these cases, you do not need to install a cross-compiler yourself. For other cases, like building on a RISCV64 host or targeting RISCV32, you will need to manually install a toolchain.

## Linux

If you are running Debian/Ubuntu, you can obtain a cross-compiler by doing the following:	

```bash
$ sudo apt-get install g++-i686-linux-gnu       # To target ia32
$ sudo apt-get install g++-x86-64-linux-gnu     # To target x64
$ sudo apt-get install g++-arm-linux-gnueabihf  # To target arm
$ sudo apt-get install g++-aarch64-linux-gnu    # To target arm64
$ sudo apt-get install g++-riscv64-linux-gnu    # To target riscv64
```

## Android

Follow instructions under ["One-time Setup" under Android](Building-the-Dart-VM-for-Android)

# Building

## Linux

With the default Debian/Ubuntu toolchains, simply do:

```bash
$ ./tools/build.py --no-clang --mode release --arch arm create_sdk
$ ./tools/build.py --no-clang --mode release --arch arm64 create_sdk
$ ./tools/build.py --no-clang --mode release --arch riscv64 create_sdk
```

You can also produce only a Dart VM runtime, no SDK, by replacing `create_sdk` with `runtime`. This process involves also building a VM that targets ia32/x64, which is used to generate a few parts of the SDK.

You can use a different toolchain using the -t switch. For example, if the path to your gcc is /path/to/toolchain/prefix-gcc, then you'd invoke the build script with:

```bash
$ ./tools/build.py --no-clang -m release -a arm -t arm=/path/to/toolchain/prefix create_sdk
$ ./tools/build.py --no-clang -m release -a arm64 -t arm64=/path/to/toolchain/prefix create_sdk
$ ./tools/build.py --no-clang -m release -a riscv32 -t riscv32=/path/to/toolchain/prefix create_sdk
$ ./tools/build.py --no-clang -m release -a riscv64 -t riscv64=/path/to/toolchain/prefix create_sdk
```

## Android

The standalone Dart VM can also target Android.

```
$ ./tools/build.py --mode=release --arch=arm --os=android create_sdk
$ ./tools/build.py --mode=release --arch=arm64 --os=android create_sdk
$ ./tools/build.py --mode=release --arch=riscv64 --os=android create_sdk
```

## Debian Packages

You can create Debian packages targeting ARM or RISC-V as follows:

```
$ ./tools/linux_dist_support/create_tarball.py
$ ./tools/linux_dist_support/create_debian_packages.py -a {ia32, x64, arm, arm64, riscv64}
```
