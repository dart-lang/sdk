# Compiling Dart to WebAssembly (internal SDK developer notes)

**This page contains notes for how to compile to WebAssembly for SDK contributors.
If you are a Dart developer, using a prebuilt Dart SDK, please refer to the
[regular documentation](https://dart.dev/web/wasm).**

**Note:** This feature is under active development,
and is currently considered experimental.
The tracking issue is [#32894](https://github.com/dart-lang/sdk/issues/32894).

## Running dart2wasm as an SDK contributor

You don't need to build the Dart SDK to run dart2wasm, as long as you have a Dart SDK installed and have the [Dart SDK repository checked out](https://github.com/dart-lang/sdk/wiki/Building#getting-the-source). NB: the SDK must be checked out using depot tools and not just cloned from this repo.

To compile a Dart file to Wasm, in a checkout of the Dart SDK repository, run:

```
dart --enable-asserts pkg/dart2wasm/bin/dart2wasm.dart <options> <input file>.dart <output file>.wasm
```

### Compiler options

| Option                                  | Default | Description |
| --------------------------------------- | ------- | ----------- |
| `--dart-sdk=`*path*                     | relative to script | The location of the `sdk` directory inside the Dart SDK, containing the core library sources.
| `--platform=`*path*                     | none    | The location of the platform `dill` file containing the compiled core libraries.
| `--depfile=`*path*                      | none    | Write a Ninja depfile listing the input sources for the compilation.
| `--`[`no-`]`enable-asserts`             | no      | Enable assertions at runtime.
| `--`[`no-`]`export-all`                 | no      | Export all functions; otherwise, just export `main`.
| `--`[`no-`]`import-shared-memory`       | no      | Import a shared memory buffer. If this is on, `--shared-memory-max-pages` must also be specified.
| `--`[`no-`]`inlining`                   | yes     | Enable function inlining.
| `--inlining-limit` *size*               | 0       | Always inline functions no larger than this number of AST nodes, if inlining is enabled.
| `--`[`no-`]`js-compatibility`           | no      | Enable JS compatibility mode.
| `--`[`no-`]`name-section`               | yes     | Emit Name Section with function names.
| `--`[`no-`]`omit-type-checks`           | no      | Omit runtime type checks, such as covariance checks and downcasts.
| `--`[`no-`]`polymorphic-specialization` | no      | Do virtual calls by switching on the class ID instead of using `call_indirect`.
| `--`[`no-`]`print-kernel`               | no      | Print IR for each function before compiling it.
| `--`[`no-`]`print-wasm`                 | no      | Print Wasm instructions of each compiled function.
| `--`[`no-`]`verify-type-checks`         | no      | Instrument code to verify that type check optimizations produce the correct result.
| `--shared-memory-max-pages` *pagecount* |         | Max size of the imported memory buffer. If `--shared-import-memory` is specified, this must also be specified.
| `--watch` *offset*                      |         | Print stack trace leading to the byte at offset *offset* in the `.wasm` output file. Can be specified multiple times.

Dart2Wasm will output a `wasm` file, containing Dart compiled to Wasm, as well as an `mjs` file containing the runtime. The result can be run with:

```
d8 pkg/dart2wasm/bin/run_wasm.js -- /abs/path/to/<output file>.mjs <output file>.wasm
```

Where `d8` is the [V8 developer shell](https://v8.dev/docs/d8).

## Imports and exports

To import a function, declare it as a global, external function and mark it with a `wasm:import` pragma indicating the imported name (which must be two identifiers separated by a dot):
```dart
@pragma("wasm:import", "foo.bar")
external void fooBar(Object object);
```
which will call `foo.bar` on the host side:
```javascript
var foo = {
    bar: function(object) { /* implementation here */ }
};
```
To export a function, mark it with a `wasm:export` pragma:
```dart
@pragma("wasm:export")
void foo(double x) { /* implementation here */  }

@pragma("wasm:export", "baz")
void bar(double x) { /* implementation here */  }
```
With the Wasm module instance in `inst`, these can be called as:
```javascript
inst.exports.foo(1);
inst.exports.baz(2);
```

### Types to use for interop

In the signatures of imported and exported functions, use the following types:

- For numbers, use `double`.
- For JS objects, use a JS interop type, e.g. `JSAny`, which translates to the Wasm `externref` type. These can be passed around and stored as opaque values on the Dart side.
- For Dart objects, use the corresponding Dart type. This will be emitted as `anyref` and automatically converted to and from the Dart type at the boundary.

## Detecting whether code is running as WebAssembly

`dart2wasm` defines `dart.tool.dart2wasm` as `true`, meaning that `bool.fromEnvironment('dart.tool.dart2wasm')` can be used in a constant context to determine whether it was
compiled to WebAssembly.
