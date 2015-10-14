Dart-JavaScript Interop
=======================

Status
------

Version 0.6.0 is a complete rewrite of package:js 

The package now only contains annotations specifying the shape of the
JavaScript API to import into Dart.
The core implementation is defined directly in Dart2Js, Dartium, and DDC.

**Warning: support in Dartium and Dart2Js is still in progress.

#### Example - TODO(jacobr)

Configuration and Initialization
--------------------------------

### Adding the dependency

Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  js: ">=0.6.0 <0.7.0"
```

##### main.html

```html
<html>
  <head>
  </head>
  <body>
    <script type="application/dart" src="main.dart"></script>
  </body>
</html>
```

##### main.dart

TODO(jacobr): example under construction.
```dart
library main;

import 'package:js/js.dart';

main() {
}
```

Contributing and Filing Bugs
----------------------------

Please file bugs and features requests on the Github issue tracker: https://github.com/dart-lang/js-interop/issues

We also love and accept community contributions, from API suggestions to pull requests. Please file an issue before beginning work so we can discuss the design and implementation. We are trying to create issues for all current and future work, so if something there intrigues you (or you need it!) join in on the discussion.

All we require is that you sign the Google Individual Contributor License Agreement https://developers.google.com/open-source/cla/individual?csw=1
