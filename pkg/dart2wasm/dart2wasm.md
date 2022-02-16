## Running dart2wasm

You don't need to build the Dart SDK to run dart2wasm, as long as you have a Dart SDK installed.

To compile a Dart file to Wasm, run:

`dart --enable-asserts pkg/dart2wasm/bin/dart2wasm.dart` *options* *infile*`.dart` *outfile*`.wasm`

where *options* include:

| Option                                  | Default | Description |
| --------------------------------------- | ------- | ----------- |
| `--dart-sdk=`*path*                     | relative to script | The location of the `sdk` directory inside the Dart SDK, containing the core library sources.
| `--`[`no-`]`export-all`                 | no      | Export all functions; otherwise, just export `main`.
| `--`[`no-`]`inlining`                   | no      | Inline small functions.
| `--`[`no-`]`lazy-constants`             | no      | Instantiate constants lazily.
| `--`[`no-`]`local-nullability`          | no      | Use non-nullable types for non-nullable locals and temporaries.
| `--`[`no-`]`name-section`               | yes     | Emit Name Section with function names.
| `--`[`no-`]`nominal-types`              | no      | Emit experimental nominal types.
| `--`[`no-`]`parameter-nullability`      | yes     | Use non-nullable types for non-nullable parameters and return values.
| `--`[`no-`]`polymorphic-specialization` | no      | Do virtual calls by switching on the class ID instead of using `call_indirect`.
| `--`[`no-`]`print-kernel`               | no      | Print IR for each function before compiling it.
| `--`[`no-`]`print-wasm`                 | no      | Print Wasm instructions of each compiled function.
| `--`[`no-`]`runtime-types`              | yes     | Use RTTs for allocations and casts.
| `--`[`no-`]`string-data-segments`       | no      | Use experimental array init from data segment for string constants.
| `--watch` *offset*                      |         | Print stack trace leading to the byte at offset *offset* in the `.wasm` output file. Can be specified multiple times.

The resulting `.wasm` file can be run with:

`d8 --experimental-wasm-gc --wasm-gc-js-interop pkg/dart2wasm/bin/run_wasm.js -- `*outfile*`.wasm`

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
- For Dart objects, use the corresponding Dart type. The fields of the underlying representation can be accessed on the JS side as `.$field0`, `.$field1` etc., but there is currently no defined way of finding the field index of a particular Dart field, so this mechanism is mainly useful for special objects with known layout.
- For JS objects, use the `WasmAnyRef` type (or `WasmAnyRef?` as applicable) from the `dart:wasm` package. These can be passed around and stored as opaque values on the Dart side.
