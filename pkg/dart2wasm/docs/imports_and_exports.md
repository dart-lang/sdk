## Imports and exports

**NOTE**: This is for internal usage only and not intended for end-users (yet).
See tracking issue for eventually exposing this at [github.com/dart-lang/sdk/issues/55856](https://github.com/dart-lang/sdk/issues/55856)

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
- For Dart objects, use the corresponding Dart type. This will be emitted as `anyref` and automatically converted to and from `externref` at the boundary
