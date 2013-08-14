html5lib in Pure Dart
=====================

This is a pure [Dart][dart] [html5 parser][html5parse]. It's a port of
[html5lib](http://code.google.com/p/html5lib/) from Python. Since it's 100%
Dart you can use it safely from a script or server side app.

Eventually the parse tree API will be compatible with [dart:html][d_html], so
the same code will work on the client and the server.

Installation
------------

Add this to your `pubspec.yaml` (or create it):
```yaml
dependencies:
  html5lib: any
```
Then run the [Pub Package Manager][pub] (comes with the Dart SDK):

    pub install

Usage
-----

Parsing HTML is easy!
```dart
import 'package:html5lib/parser.dart' show parse;
import 'package:html5lib/dom.dart';

main() {
  var document = parse(
      '<body>Hello world! <a href="www.html5rocks.com">HTML5 rocks!');
  print(document.outerHtml);
}
```

You can pass a String or list of bytes to `parse`.
There's also `parseFragment` for parsing a document fragment, and `HtmlParser`
if you want more low level control.

Running Tests
-------------

```bash
# From Dart SVN checkout
./tools/build.py -m release
./tools/test.py -m release html5lib
./tools/test.py -m release -r drt html5lib
```

[dart]: http://www.dartlang.org/
[html5parse]: http://dev.w3.org/html5/spec/parsing.html
[d_html]: http://api.dartlang.org/docs/continuous/dart_html.html
[files]: http://html5lib.googlecode.com/hg/python/html5lib/
[pub]: http://www.dartlang.org/docs/pub-package-manager/
