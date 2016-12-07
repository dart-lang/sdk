Methods and annotations to specify interoperability with JavaScript APIs.

*This packages requires Dart SDK 1.13.0.*

*This is beta software. Please files [issues].*

### Adding the dependency

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  js: ^0.6.0
```

### Example

See the [Chart.js Dart API](https://github.com/google/chartjs.dart/) for an
end-to-end example.

### Usage

#### Calling methods

```dart
// Calls invoke JavaScript `JSON.stringify(obj)`.
@JS("JSON.stringify")
external String stringify(obj);
```

#### Classes and Namespaces

```dart
@JS('google.maps')
library maps;

import "package:js/js.dart";

// Invokes the JavaScript getter `google.maps.map`.
external Map get map;

// `new Map` invokes JavaScript `new google.maps.Map(location)`
@JS()
class Map {
  external Map(Location location);
  external Location getLocation();
}

// `new Location(...)` invokes JavaScript `new google.maps.LatLng(...)`
//
// We recommend against using custom JavaScript names whenever
// possible. It is easier for users if the JavaScript names and Dart names
// are consistent.
@JS("LatLng")
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

If you want to use `printOptions` from Dart, you cannot simply pass a Dart `Map`
object – they are "opaque" in JavaScript.


Instead, create a Dart class with both the `@JS()` and
`@anonymous` annotations.

```dart
// Dart
void main() {
  printOptions(new Options(responsive: true));
}

@JS()
external printOptions(Options options);

@JS()
@anonymous
class Options {
  external bool get responsive;

  external factory Options({bool responsive});
}
```

NB: This _anonymous_ class must have an unnamed _factory constructor_.

#### Passing functions to JavaScript.

If you are passing a Dart function to a JavaScript API, you must wrap it using
`allowInterop` or `allowInteropCaptureThis`.

## Contributing and Filing Bugs

Please file bugs and features requests on the [Github issue tracker][issues].

We also love and accept community contributions, from API suggestions to pull requests.
Please file an issue before beginning work so we can discuss the design and implementation.
We are trying to create issues for all current and future work, so if something there intrigues you (or you need it!) join in on the discussion.

Code contributors must sign the
[Google Individual Contributor License Agreement](https://developers.google.com/open-source/cla/individual?csw=1).

[issues]: https://goo.gl/j3rzs0
