## 0.26.0-alpha.0

* API change: `UriResolver.resolveUri(..)` now takes an optional `actualUri`.

## 0.25.3-alpha.0

* Add hook for listening to implicitly analyzed files
* Add a PathFilter and AnalysisOptionsProvider utility classes to aid
  clients in excluding files from analysis when directed to do so by an
  options file.

## 0.25.2

* Requires Dart SDK 1.12-dev or greater
* Enable null-aware operators (DEP 9) by default.
* Generic method support in the element model.

## 0.25.2-alpha.1

* `dart:sdk` extension `.sdkext` changed to `_sdkext` (to play nicer with pub).

## 0.25.2-alpha.0

* Initial support for analyzing `dart:sdk` extensions from `.sdkext`. 

## 0.25.1

* (Internal) code reorganization to address analysis warnings due to SDK reorg.
* First steps towards `.packages` support.

## 0.25.0

* Commandline interface moved to dedicated `analyzer_cli` package. Files moved:
  * `bin/analyzer.dart`
  * `lib/options.dart`
  * `lib/src/analyzer_impl.dart`
  * `lib/src/error_formatter.dart`
* Removed dependency on the `args` package.

## 0.22.1

* Changes in the async/await support.


## 0.22.0

  New API:
  
* `Source.uri` added.

  Breaking changes:

* `DartSdk.fromEncoding` replaced with `fromFileUri`.
* `Source.resolveRelative` replaced with `resolveRelativeUri`.
