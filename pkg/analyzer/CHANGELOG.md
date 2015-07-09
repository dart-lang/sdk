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
