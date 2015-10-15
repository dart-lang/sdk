Methods and annotations to specify interoperability with JavaScript APIs.

*Note: This package is beta software.*

*Note: This packages requires Dart SDK `>=1.13.0-dev.7`.*

### Adding the dependency

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  js: ^0.6.0-beta
```

#### Passing functions to JavaScript.

If you are passing a Dart function to a JavaScript API, you must wrap it using
`allowInterop` or `allowInteropCaptureThis`.

### Examples

There is a [full example](https://github.com/dart-lang/sdk/tree/master/pkg/js/example) hosted with the `package:js` source code.

#### Calling methods

```dart
// Calls invoke JavaScript `JSON.stringify(obj)`.
@Js("JSON.stringify")
external String stringify(obj);
```

#### Classes and Namespaces

```dart
@Js('google.maps')
library maps;

// Invokes the JavaScript getter `google.maps.map`.
external Map get map;

// `new Map` invokes JavaScript `new google.maps.Map(location)`
@Js()
class Map {
  external Map(Location location);
  external Location getLocation();
}

// `new Location(...)` invokes JavaScript `new google.maps.LatLng(...)`
//
// We recommend against using custom JavaScript names whenever
// possible. It is easier for users if the JavaScript names and Dart names
// are consistent.
@Js("LatLng")
class Location {
  external Location(num lat, num lng);
}
```

#### Maps

Dart `Map` objects, including literals, are "opaque" in JavaScript.
You must create Dart classes for each of these.

```js
// JavaScript
printOptions({responsive: true});
```

```dart
// Dart
void main() {
  printOptions(new Options(responsive: true));
}

@Js()
external printOptions(Options options);

@Js()
class Options {
  external bool get responsive;

  external factory Options({bool responsive});
}
```

## Contributing and Filing Bugs

Please file bugs and features requests on the [Github issue tracker](https://github.com/dart-lang/js-interop/issues).

We also love and accept community contributions, from API suggestions to pull requests.
Please file an issue before beginning work so we can discuss the design and implementation.
We are trying to create issues for all current and future work, so if something there intrigues you (or you need it!) join in on the discussion.

Code contributors must sign the
[Google Individual Contributor License Agreement](https://developers.google.com/open-source/cla/individual?csw=1).
