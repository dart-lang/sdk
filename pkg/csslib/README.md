csslib in Pure Dart
===================

This is a pure [Dart][dart] [CSS parser][cssparse]. Since it's 100%
Dart you can use it safely from a script or server side app.

Installation
------------

Add this to your `pubspec.yaml` (or create it):
```yaml
dependencies:
  csslib: any
```
Then run the [Pub Package Manager][pub] (comes with the Dart SDK):

    pub install

Usage
-----

Parsing CSS is easy!
```dart
import 'package:csslib/parser.dart' show parse;
import 'package:csslib/css.dart';

main() {
  var stylesheet = parse(
      '.foo { color: red; left: 20px; top: 20px; width: 100px; height:200px }');
  print(stylesheet.toString());
}
```

You can pass a String or list of bytes to `parse`.


Updating
--------

You can upgrade the library with:

    pub update

Disclaimer: the APIs are not finished. Updating may break your code. If that
happens, you can check the
[commit log](https://github.com/dart-lang/csslib/commits/master), to figure
out what the change was.

If you want to avoid breakage, you can also put the version constraint in your
`pubspec.yaml` in place of the word `any`.

Running Tests
-------------

All tests (both canary and suite) should be passing.  Canary are quick test
verifies that basic CSS is working.  The suite tests are a comprehensive set of
~11,000 tests.

```bash
export DART_SDK=path/to/dart/sdk

# Make sure dependencies are installed
pub install

# Run command both canary and the suite tests
test/run.sh
```

  Run only the canary test:

```bash
 test/run.sh canary
```

  Run only the suite tests:

```bash
 test/run.sh suite
```

[dart]: http://www.dartlang.org/
[pub]: http://www.dartlang.org/docs/pub-package-manager/
