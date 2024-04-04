# Contributing guide

When making changes to `package:dtd` and `package:dtd_impl` at the same
time, you'll need to
[build the Dart SDK](https://github.com/dart-lang/sdk/wiki/Building#building)
to ensure that changes to
`package:dtd_impl` are picked up in the DTD snapshot.

## Helpful aliases

Consider adding these aliases to your `.zshrc` file for convenience. For
non-macOS platforms, replace "xcodebuild" with "out".
```
# Builds the entire Dart SDK. Run from the sdk/ directory.
alias build-dart='./tools/build.py -mrelease create_sdk'

# The create_platform_sdk target will work exactly the same as the
# `create_sdk` target but without building the web tooling.
alias build-dart-fast='./tools/build.py -mrelease create_platform_sdk'

# The dart exe that was built by running 'build-dart' or 'build-dart-fast'
# will be located here. Create an alias for convenience of using the dart exe.
alias sdkdart='/absolute_path_to/sdk/xcodebuild/ReleaseX64/dart-sdk/bin/dart'

# The runtime target will only build what the VM needs to run, but will output
# the compiled dart binary at `xcodebuild/ReleaseX64/dart` instead of
# `xcodebuild/ReleaseX64/dart-sdk/bin/dart`. Runtime is a bit faster than
# `create_platform_sdk`, but both are faster than `create_sdk`.
alias build-dart-runtime='./tools/build.py -mrelease runtime'

# The dart exe that was built by running `build-dart-runtime`.
alias sdkruntime='/absolute_path_to/sdk/xcodebuild/ReleaseX64/dart'
```

After building the Dart SDK with your local changes, use the `dart`
executable that you just built to run commands that you want your
local changes applied to (e.g. `sdkdart run ...`, `sdkdart test ...`).
