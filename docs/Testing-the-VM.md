> [!IMPORTANT]
> This page was copied from https://github.com/dart-lang/sdk/wiki and needs review.
> Please [contribute](../CONTRIBUTING.md) changes to bring it up-to-date -
> removing this header - or send a CL to delete the file.

---

## JIT

```
./tools/build.py -m all runtime
./tools/test.py -m all
./tools/test.py -m all --checked
```

## [AddressSanitizer](https://github.com/google/sanitizers/wiki/AddressSanitizer)

```
./tools/gn.py -m release --asan
./tools/build.py -m release runtime
./tools/test.py -m release --builder-tag=asan -t240
```

## [ThreadSanitizer](https://github.com/google/sanitizers/wiki/ThreadSanitizerCppManual)

```
./tools/gn.py -m release --tsan
./tools/build.py -m release runtime
./tools/test.py -m release
```

## Noopt

```
./tools/build.py -mdebug,release runtime_and_noopt
./tools/test.py -mdebug,release --noopt
```

## Precompilation

```
./tools/build.py -mrelease runtime_precompiled
./tools/test.py -mrelease -cprecompiler -rdart_precompiled
```

## Precompilation on Android devices
```
./tools/build.py -mrelease -aarm --os=android runtime_precompiled
export PATH=$PATH:$PWD/third_party/android_tools/sdk/platform-tools
./tools/test.py -mrelease -aarm --system=android -cprecompiler -rdart_precompiled --use-blobs
```

## App snapshots

```
./tools/build.py -mall runtime
./tools/test.py -mall -capp_jit
```
