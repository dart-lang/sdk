# Package `js_shared`:

This code is a compile time dependency of dart2js and DDC. It is imported as
a `package:` import by both compilers.

There is an exact copy in the SDK of the libraries in the
`pkg/js_shared/lib/synced` sub-directory.
Those libraries are imported as `dart:` imports by the dart2js and DDC runtime
libraries.

*Important*: all code under `pkg/js_shared/lib/synced` must be kept in sync with
the runtime (in `sdk/lib/_internal/js_shared/lib/synced`) at all times. The
`test/in_sync_test.dart` test verifies this.
