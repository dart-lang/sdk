## 0.9.4

* Update `SpanFormatException` with `source` and `offset`.

* All methods that take `Span`s, `Location`s, and `SourceFile`s as inputs now
  also accept the corresponding `source_span` classes as well. Using the old
  classes is now deprecated and will be unsupported in version 0.10.0.

## 0.9.3

* Support writing SingleMapping objects to source map version 3 format.
* Support the `sourceRoot` field in the SingleMapping class.
* Support updating the `targetUrl` field in the SingleMapping class.

## 0.9.2+2

* Fix a bug in `FixedSpan.getLocationMessage`.

## 0.9.2+1

* Minor readability improvements to `FixedSpan.getLocationMessage` and
  `SpanException.toString`.

## 0.9.2

* Add `SpanException` and `SpanFormatException` classes.

## 0.9.1

* Support unmapped areas in source maps.

* Increase the readability of location messages.
