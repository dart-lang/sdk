> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

# Building and Testing

## AddressSanitizer

```
export ASAN_OPTIONS="handle_segv=0:detect_leaks=1:detect_stack_use_after_return=0:disable_coredump=0:abort_on_error=1"
export ASAN_SYMBOLIZER_PATH="$PWD/buildtools/linux-x64/clang/bin/llvm-symbolizer"
./tools/build.py --mode release --arch x64 --sanitizer asan runtime runtime_precompiled create_sdk
./tools/sdks/dart-sdk/bin/dart ./tools/test.dart -n dartk-asan-linux-release-x64 -N dartk-asan-linux-release-x64
```

## MemorySanitizer

```
export MSAN_OPTIONS="handle_segv=0:detect_leaks=1:detect_stack_use_after_return=0:disable_coredump=0:abort_on_error=1"
export MSAN_SYMBOLIZER_PATH="$PWD/buildtools/linux-x64/clang/bin/llvm-symbolizer"
./tools/build.py --mode release --arch x64 --sanitizer msan runtime runtime_precompiled create_sdk
./tools/sdks/dart-sdk/bin/dart ./tools/test.dart -n dartk-asan-linux-release-x64 -N dartk-msan-linux-release-x64
```

## LeakSanitizer

```
export ASAN_OPTIONS="handle_segv=0:detect_leaks=1:detect_stack_use_after_return=0:disable_coredump=0:abort_on_error=1"
export ASAN_SYMBOLIZER_PATH="$PWD/buildtools/linux-x64/clang/bin/llvm-symbolizer"
./tools/build.py --mode release --arch x64 --sanitizer lsan runtime runtime_precompiled create_sdk
./tools/sdks/dart-sdk/bin/dart ./tools/test.dart -n dartk-asan-linux-release-x64 -N dartk-lsan-linux-release-x64
```
## ThreadSanitizer

```
export TSAN_OPTIONS="handle_segv=0:disable_coredump=0:abort_on_error=1"
export TSAN_SYMBOLIZER_PATH="$PWD/buildtools/linux-x64/clang/bin/llvm-symbolizer"
./tools/build.py --mode release --arch x64 --sanitizer tsan dart runtime runtime_precompiled create_sdk
./tools/sdks/dart-sdk/bin/dart ./tools/test.dart -n dartk-asan-linux-release-x64 -N dartk-tsan-linux-release-x64
```
## UndefinedBehaviorSanitizer

```
export UBSAN_OPTIONS="handle_segv=0:disable_coredump=0:abort_on_error=1"
export UBSAN_SYMBOLIZER_PATH="$PWD/buildtools/linux-x64/clang/bin/llvm-symbolizer"
./tools/build.py --mode release --arch x64 --sanitizer ubsan runtime runtime_precompiled create_sdk
./tools/sdks/dart-sdk/bin/dart ./tools/test.dart -n dartk-linux-release-x64 -N dartk-ubsan-linux-release-x64
```

The `handle_segv=0` is only crucial when running through the test suite, wherein several tests are expected to segfault, and will fail if ASan installs its own segfault handler.

# Development #

AddressSanitizer works at the C++ language level, hence does not automatically know about code that Dart VM's JIT compiler generates, nor about low-level direct manipulation of the stack from C++ code.

Use the macro `ASAN_UNPOISON(ptr, len)` to explicitly inform ASan about a region of the stack that has been manipulated outside normal portable C++ code.

## Stack pointer ##

When running with detect_stack_use_after_return=1, ASan will return a fake stack pointer when taking the address of a local variable. Use `Isolate::GetCurrentStackPointer()` to get the real stack pointer (calls a tiny pregenerated stub).
