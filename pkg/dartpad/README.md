# DartPad

`package:dartpad` is a library for building web applications that enable users
to prototype Dart and Flutter in the browser.

This package provides the functionality for running a Dart or Flutter
development environment in the browser. By enabling you launch and communicate
with:
 * A **worker**, a dart2wasm compiled _Web Worker_ featuring:
   * An in-memory file system,
   * The Dart LSP server,
   * The Dart Development Compiler (DDC),
   * A subset of `dart pub` commands for dependency resolution.
 * A **Sandbox**, an isolated `iframe` containing bootstrap code necessary to:
   * Run, hot-reload and hot-restart DDC compiled Dart code, and,
   * Proxy console output and _unhandled exceptions_ out of the iframe.

To build a custom dartpad-like experience, you simply have to launch the worker,
connect the _language server_ to your editor, compile code and tell the sandbox
to run said code, while presenting console output to the user.

## Limitations
As of writing there are no support for:

 * Build hooks,
 * Flutter plugins,
 * Flutter assets,
 * Code generation with `build_runner`.

It might be possible to support some of these features in the future.
