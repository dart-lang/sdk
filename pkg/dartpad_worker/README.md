# DartPad worker

This package contains a worker intended to be compiled to wasm and run as a
_Web Worker_ in the browser by `package:dartpad`. This worker environment has
an in-memory file-system with DDC, LSP and pub client.

This package is not intended to be published, instead the resulting binaries
and assets should be published (e.g., to a CDN).

## Architecture
A dartpad-like experience built with `package:dartpad` consists of 3 components:
 * The _editor_, the main application, built using `package:dartpad`. This is
   where the UI, code editor, file browser, etc lives. You may also think of
   this as the main application that orchestrates everything else.
 * The _worker_, a development environment that runs in a _Web Worker_, launched
   using `package:dartpad`. This hosts an in-memory file-system, where you can
   run a `pub get`, start a language server or compile dart files with DDC. You
   can also think of this as your Dart SDK.
 * The _sandbox_, a sandboxed iframe, where dart files compiled in the _worker_
   can be executed, with support for hot-reload, hot-restart and extraction of
   `console.log` and unhandled exceptions.

Communication between the components above is entirely async, and happens using
[JSON-RPC 2.0], though the APIs are encapsulated by `package:dartpad`, so users
do not have to manage RPC messages themselves. A user of `package:dartpad` gets
an convinient asynchronous API for talking to the worker and sandbox. But to
spawn a worker or sandbox, a user of `package:dartpad` must provide:
 * `assetBaseUrl`, the location of binaries and assets created from
   `pkg/dartpad_worker`.
 * `sdkLocation`, the location of the _DartPad SDK_ to use, this includes
   SDK files and runtime DDC modules to be used.

The `assetBaseUrl` should point to a location hosting the files from
`out/ReleaseX64/dartpad/` built with
`./tools/build.py -m release -a x64 dartpad`.
This includes WASM compiled worker, auxiliary JS files for loading into a
_Web Worker_, DDC module loader, sandbox communication layer.
But from the perspective of a user of `package:dartpad`, the `assetBaseUrl`
should simply point to a collection of files built from the Dart SDK repository.
The Dart team will publish these files as part of the release process for the
Dart SDK.

The `sdkLocation` should point to the location of a _DartPad SDK_.
A _DartPad SDK_ is a folder that contains the following entrypoints:
 * `sdk.tar`, a bundle of files to be loaded into the in-memory filesystem of
   the worker, and,
 * `sdk.js`, a bundle of DDC modules to be loaded into the sandbox before we
   attempt to run anything.

A _DartPad SDK_ may contain additional assets and resources referenced from
`sdk.js` or loaded by the running application.

As of the moment, `out/ReleaseX64/dartpad/` also contains a `dart/` folder that
works as _DartPad SDK_ (`sdkLocation`) for a Dart-only environment.
For a Flutter environment a _DartPad SDK_ can be built using
`pkg/dartpad_worker/setup_local_flutter.dart`.

From the perspective of a user of `package:dartpad`, the `sdkLocation` should
simply point to a collection of files built from the Dart or Flutter SDK
repository.
Current thinking is that the Dart team will publish these files as part of the
release process for the Dart and Flutter SDKs.

It may be possible that in the future, a default value for `assetBaseUrl` is
hardcoded into `package:dartpad`, along with `sdkLocation` default values for
Dart and Flutter SDKs. It's also possible that framework authors building on top
of the Dart or Flutter SDK, may want to publish their own _DartPad SDK_ with
pre-compiled DDC modules. Exactly, how to keep such an effort maintainable is
still TBD.

[JSON-RPC 2.0]: https://www.jsonrpc.org/specification

## Testing
These tests require the assets be built. Build these locally with:

```sh
./tools/build.py -m release -a x64 dartpad
```

And run tests locally with `dart test`, see `dart_test.yaml` for details on the
configuration.

To run Flutter specific tests you also run:
```sh
dart pkg/dartpad_worker/setup_local_flutter.dart
```

This will only work if your flutter installation has the same dill version as
your Dart SDK checkout. This is arguably not ideal, and these tests do not run
in CI.

