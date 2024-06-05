> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

# Introduction

The Dart VM runs on a variety of ARM processors on Linux and Android. This document explains how to build the Dart VM and SDK to target these platforms.

# Cross-compiling

If you are building natively on the device you will be running on, you can skip this step.  The build scripts download a cross-compilation toolchain using clang that supports ia32, x64, arm and arm64, so you do not need to install a cross-compiler yourself unless you want to target riscv.

## Linux

If you are running Debian/Ubuntu, you can obtain a cross-compiler by doing the following:	

```	
$ sudo apt-get install g++-arm-linux-gnueabihf  # For 32-bit ARM (ARMv7)	
$ sudo apt-get install g++-aarch64-linux-gnu    # For 64-bit ARM (ARMv8)
$ sudo apt-get install g++-riscv64-linux-gnu    # For 64-bit RISC-V (RV64GC)
```

## Android

Follow instructions under ["One-time Setup" under Android](Building-the-Dart-VM-for-Android)

# Building

## Linux

With the default Debian/Ubuntu toolchains, simply do:

```
$ ./tools/build.py --no-rbe --no-clang --mode release --arch arm create_sdk
$ ./tools/build.py --no-rbe --no-clang --mode release --arch arm64 create_sdk
$ ./tools/build.py --no-rbe --no-clang --mode release --arch riscv64 create_sdk
```

You can also produce only a Dart VM runtime, no SDK, by replacing `create_sdk` with `runtime`. This process involves also building a VM that targets ia32/x64, which is used to generate a few parts of the SDK.

You can use a different toolchain using the -t switch. For example, if the path to your gcc is /path/to/toolchain/prefix-gcc, then you'd invoke the build script with:

```
$ ./tools/build.py --no-rbe --no-clang -m release -a arm -t arm=/path/to/toolchain/prefix create_sdk
$ ./tools/build.py --no-rbe --no-clang -m release -a arm64 -t arm64=/path/to/toolchain/prefix create_sdk
$ ./tools/build.py --no-rbe --no-clang -m release -a riscv32 -t riscv32=/path/to/toolchain/prefix create_sdk
$ ./tools/build.py --no-rbe --no-clang -m release -a riscv64 -t riscv64=/path/to/toolchain/prefix create_sdk
```

## Android

The standalone Dart VM can also target Android.

```
$ ./tools/build.py --mode=release --arch=arm --os=android create_sdk
$ ./tools/build.py --mode=release --arch=arm64 --os=android create_sdk
$ ./tools/build.py --mode=release --arch=riscv64 --os=android create_sdk
```

For all of these configurations, the runtime only can be built using the runtime target as above.

## Debian Packages

You can create Debian packages targeting ARM or RISC-V as follows:

```
$ ./tools/linux_dist_support/create_tarball.py
$ ./tools/linux_dist_support/create_debian_packages.py -a {ia32, x64, arm, arm64, riscv64}
```
