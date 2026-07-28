# RISC-V 32

The default toolchain setups do not work for riscv32. Ubuntu does not provide a `g++-riscv64-linux-gnu` package, and Fuchsia Clang does not support riscv32 as a target.

You can build a toolchain locally, or get one from https://toolchains.bootlin.com/, and point build.py at this toolchain.

```
RV32_TOOLCHAIN="$HOME/toolchains/riscv32-ilp32d--glibc--stable-2025.08-1"
./tools/build.py -mrelease -ariscv32 --no-clang --no-rbe --toolchain=riscv32=$RV32_TOOLCHAIN/bin/riscv32-linux-

export QEMU_LD_PREFIX="$RV32_TOOLCHAIN/riscv32-buildroot-linux-gnu/sysroot"
./tools/test.py -mrelease -ariscv32 --use-qemu --gen-snapshot-format=elf -cdartk,dartkp -t900 ffi
```
