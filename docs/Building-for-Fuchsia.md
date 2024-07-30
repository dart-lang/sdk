# Setup

Download and install the Dart source tree using the standard instructions for building Dart.

To build for Fuchsia, you must first update your `.gclient file with:
```
    "custom_vars": {
      "download_fuchsia_deps": True,
    },
```

# Building

```bash
./tools/build.py --mode=release --os=fuchsia --arch=arm64 create_sdk runtime
```


# Testing

```bash
./tools/test.py -nvm-fuchsia-release-arm64 -j4 ffi
```

