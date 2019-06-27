Methods and annotations to specify interoperability with JavaScript APIs.

### Example

See the [Chart.js Dart API](https://github.com/google/chartjs.dart/) for an
end-to-end example.

### Usage

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



## Reporting issues

Please file bugs and features requests on the [SDK issue tracker][issues].

[issues]: https://goo.gl/j3rzs0
