# Debugging the Dart VM with QEMU

The Dart VM implements simulators for ARM and RISC-V, allowing developers with X64 machines to test compiler changes against all 6 supported architectures locally. However, these simulators only handle compiled Dart code, with the runtime still running on X64. This means compiled Dart code and any foreign libraries are in mismatched architectures, which is not supported by Dart's FFI. To test FFI we need the runtime and foreign libraries to also be in ARM/RISC-V. This can still be tested on an X64 machine by cross compiling and running under QEMU.

```
$ sudo apt install qemu-user g++-aarch64-linux-gnu
$ tools/build.py --arch arm64 runtime runtime_precompiled
$ QEMU_LD_PREFIX=/usr/aarch64-linux-gnu/ qemu-aarch64 out/DebugXARM64/dartvm hello.dart.dill
Hello, world!
```

## Debugging with GDB

```
$ sudo apt install qemu-user g++-aarch64-linux-gnu gdb-multiarch
$ QEMU_LD_PREFIX=/usr/aarch64-linux-gnu/ qemu-aarch64 -g 9090 out/DebugXARM64/dartvm hello.dart.dill

$ gdb-multiarch
(gdb) set sysroot /usr/aarch64-linux-gnu/
(gdb) target remote localhost:9090
(gdb) continue
```

## Running the FFI tests

```
$ sudo apt install qemu-user g++-arm-linux-gnueabihf g++-aarch64-linux-gnu g++-riscv64-linux-gnu
$ ./tools/build.py --arch simarm_x64 gen_snapshot
$ ./tools/build.py --arch arm,arm64,riscv64,simarm64_arm64 runtime runtime_precompiled
$ ./tools/test.py --arch arm,arm64,riscv64,simarm64_arm64 --use-qemu --compiler dartk,dartkp --gen-snapshot-format elf --timeout 500 ffi
```

## Tips

This is slow! You probably want to run kernel and AOT compilation outside of QEMU. You probably want to run `dartvm` directly instead of `dart`. You probably want to use gdb's `set sysroot` to avoid slow file transfers.

The `QEMU_LD_PREFIX` environment variable is preferable to the `-L` command line flag because anything involving subprocesses isn't set up to explicitly invoke through QEMU and pass `-L` down to children.

Use `Ctrl+A` to get to the QEMU monitor if the process isn't responding to `Ctrl+C`.

The `qemu-user` package doesn't provide the libc, etc for the guest architectures. The `g++` cross-compilation packages transitively include the packages that do.

The Clang downloaded by `gclient sync` doesn't support 32-bit RISC-V, and Debian/Ubuntu don't provide a `g++-riscv32-linux-gnu` package.
