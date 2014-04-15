## 0.5.0

* Renamed `Stack` to `Pipeline`.

## 0.4.0

* Access to headers for `Request` and `Response` is now case-insensitive.

* The constructor for `Request` has been simplified. 

* `Request` now exposes `url` which replaces `pathInfo`, `queryString`, and 
  `pathSegments`.

## 0.3.0+9

* Removed old testing infrastructure.

* Updated documentation address.

## 0.3.0+8

* Added a dependency on the `http_parser` package.

## 0.3.0+7

* Removed unused dependency on the `mime` package.

## 0.3.0+6

* Added a dependency on the `string_scanner` package.

## 0.3.0+5

* Updated `pubspec` details for move to Dart SDK.

## 0.3.0 2014-03-25

* `Response`
    * **NEW!** `int get contentLength`
    * **NEW!** `DateTime get expires`
    * **NEW!** `DateTime get lastModified`
* `Request`
    * **BREAKING** `contentLength` is now read from `headers`. The constructor
      argument has been removed.
    * **NEW!** supports an optional `Stream<List<int>> body` constructor argument.
    * **NEW!** `Stream<List<int>> read()` and
      `Future<String> readAsString([Encoding encoding])`
    * **NEW!** `DateTime get ifModifiedSince`
    * **NEW!** `String get mimeType`
    * **NEW!** `Encoding get encoding`

## 0.2.0 2014-03-06

* **BREAKING** Removed `Shelf` prefix from all classes.
* **BREAKING** `Response` has drastically different constructors.
* *NEW!* `Response` now accepts a body of either `String` or
  `Stream<List<int>>`.
* *NEW!* `Response` now exposes `encoding` and `mimeType`.

## 0.1.0 2014-03-02

* First reviewed release
