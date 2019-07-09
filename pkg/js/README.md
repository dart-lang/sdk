Methods and annotations to specify interoperability with JavaScript APIs.

### Example

See the [Chart.js Dart API](https://github.com/google/chartjs.dart/) for an
end-to-end example.

### Usage

All Dart code interacting with JavaScript should use the utilities provided with
`package:js`. Developers should avoid importing `dart:js` directly.

#### Calling methods

```dart
@JS()
library stringify;

import 'package:js/js.dart';

// Calls invoke JavaScript `JSON.stringify(obj)`.
@JS('JSON.stringify')
external String stringify(Object obj);
```

#### Classes and Namespaces

```dart
@JS('google.maps')
library maps;

import 'package:js/js.dart';

// Invokes the JavaScript getter `google.maps.map`.
external Map get map;

// The `Map` constructor invokes JavaScript `new google.maps.Map(location)`
@JS()
class Map {
  external Map(Location location);
  external Location getLocation();
}

// The `Location` constructor invokes JavaScript `new google.maps.LatLng(...)`
//
// We recommend against using custom JavaScript names whenever
// possible. It is easier for users if the JavaScript names and Dart names
// are consistent.
@JS('LatLng')
class Location {
  external Location(num lat, num lng);
}
```

#### JavaScript object literals

Many JavaScript APIs take an object literal as an argument. For example:
```js
// JavaScript
printOptions({responsive: true});
```

If you want to use `printOptions` from Dart a `Map<String, dynamic>` would be
"opaque" in JavaScript.

Instead, create a Dart class with both the `@JS()` and `@anonymous` annotations.

```dart
@JS()
library print_options;

import 'package:js/js.dart';

void main() {
  printOptions(Options(responsive: true));
}

@JS()
external printOptions(Options options);

@JS()
@anonymous
class Options {
  external bool get responsive;

  // Must have an unnamed factory constructor with named arguments.
  external factory Options({bool responsive});
}
```

#### Passing functions to JavaScript

If you are passing a Dart function to a JavaScript API as an argument , you must
wrap it using `allowInterop` or `allowInteropCaptureThis`. **Warning** There is
a behavior difference between the Dart2JS and DDC compilers. When compiled with
DDC there will be no errors despite missing `allowInterop` calls, because DDC
uses JS calling semantics by default. When compiling with Dart2JS the
`allowInterop` utility must be used.

#### Making a Dart function callable from JavaScript

To provide a Dart function callable from JavaScript by name use a setter
annotated with `@JS()`.

```dart
@JS()
library callable_function;

import 'package:js/js.dart';

/// Allows assigning a function to be callable from `window.functionName()`
@JS('functionName')
external set _functionName(void Function() f);

/// Allows calling the assigned function from Dart as well.
@JS()
external void functionName();

void _someDartFunction() {
  print('Hello from Dart!');
}

void main() {
  _functionName = allowInterop(_someDartFunction);
  // JavaScript code may now call `functionName()` or `window.functionName()`.
}
```

## Known limitations and bugs

### Differences betwenn Dart2JS and DDC

Dart's production and development JavaScript compilers use different calling
conventions and type representation, and therefore have different challenges in
JavaScript interop. There are currently some know differences in behavior and
bugs in one or both compilers.

#### allowInterop is required in Dart2JS, optional in DDC

DDC uses the same calling conventions as JavaScript and so Dart functions passed
as callbacks can be invoked without modification. In Dart2JS the calling
conventions are different and so `allowInterop` or `allowInteropCaptureThis`
must be used for any callback.

**Workaround:**: Always use `allowInterop` even when not required in DDC.

#### Callbacks allow extra ignored arguments in DDC

In JavaScript a caller may pass any number of "extra" arguments to a function
and they will be ignored. DDC follows this behavior, Dart2JS will have a runtime
error if a function is invoked with more arguments than expected.

**Workaround:** Write functions that take the same number of arguments as will
be passed from JavaScript. If the number is variable use optional positional
arguments.

#### DDC and Dart2JS have different representation for Maps

Passing a `Map<String, String>` as an argument to a JavaScript function will
have different behavior depending on the compiler. Calling something like
`JSON.stringify()` will give different results.

**Workaround:** Only pass object literals instead of Maps as arguments. For json
specifically use `jsonEncode` in Dart rather than a JS alternative.

#### Missing validation for anonymous factory constructors in DDC

When using an `@anonymous` class to create JavaScript object literals Dart2JS
will enforce that only named arguments are used, while DDC will allow positional
arguments but may generate incorrect code.

**Workaround:** Try builds in both development and release mode to get the full
scope of static validation.

### Sharp Edges

Dart and JavaScript have different semantics and common patterns which makes it
easy to make some mistakes, and difficult for the tools to provide safety. These
sharp edges are known pitfalls.

#### Lack of runtime type checking

The return types of methods annotated with `@JS()` are not validated at runtime,
so an incorrect type may "leak" into other Dart code and violate type system
guarantees.

**Workaround:** For any calls into JavaScript code that are not known to be safe
in their return values, validate the results manually with `is` checks.

#### List instances coming from JavaScript will always be `List<dynamic>`

A JavaScript array does not have a reified element type, so an array returned
from a JavaScript function cannot make guarantees about it's elements without
inspecting each one. At runtime a check like `result is List` may succeed, while
`result is List<String>` will always fail.

**Workaround:** Use a `.cast<String>().toList()` call to get a `List` with the
expected reified type at runtime.

#### The `JsObject` type from `dart:js` can't be used with `@JS()` annotation

`JsObject` and related code in `dart:js` uses a different approach and may not
be passed as an argument to a method annotated with `@JS()`.

**Workaround:** Avoid importing `dart:js` and only use the `package:js` provided
approach. To handle object literals use `@anonymous` on an `@JS()` annotated
class.

## Reporting issues

Please file bugs and features requests on the [SDK issue tracker][issues].

[issues]: https://goo.gl/j3rzs0
