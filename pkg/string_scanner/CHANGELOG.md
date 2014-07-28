## 0.1.0

* Switch from `source_maps`' `Span` class to `source_span`'s `SourceSpan` class.

* `new StringScanner()`'s `sourceUrl` parameter is now named to make it clear
  that it can be safely `null`.

* `new StringScannerException()` takes different arguments in a different order
  to match `SpanFormatException`.

* `StringScannerException.string` has been renamed to
  `StringScannerException.source` to match the `FormatException` interface.

## 0.0.3

* Make `StringScannerException` inherit from source_map's
  [`SpanFormatException`][].

[SpanFormatException]: (http://www.dartdocs.org/documentation/source_maps/0.9.2/index.html#source_maps/source_maps.SpanFormatException)

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
