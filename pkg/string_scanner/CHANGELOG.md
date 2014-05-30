## 0.0.2

* `new StringScanner()` now takes an optional `sourceUrl` argument that provides
  the URL of the source file. This is used for error reporting.

* Add `StringScanner.readChar()` and `StringScanner.peekChar()` methods for
  doing character-by-character scanning.

* Scanners now throw `StringScannerException`s which provide more detailed
  access to information about the errors that were thrown and can provide
  terminal-colored messages.

* Add a `LineScanner` subclass of `StringScanner` that automatically tracks line
  and column information of the text being scanned.

* Add a `SpanScanner` subclass of `LineScanner` that exposes matched ranges as
  [source map][] `Span` objects.

[source_map]: http://pub.dartlang.org/packages/source_maps
