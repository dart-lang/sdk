## 0.25.0

* Commandline interface moved to dedicated `analyzer_cli` package. Files moved:
** `bin/analyzer.dart`
** `lib/analyzer.dart`
** `lib/options.dart`
** `lib/src/analyzer_impl.dart`
** `lib/src/error_formatter.dart`
* Removed dependency on `args` package.

## 0.22.1

* Changes in the async/await support.


## 0.22.0

  New API:
  
* Source.uri added.

  Breaking changes:

* DartSdk.fromEncoding replaced with "fromFileUri".
* Source.resolveRelative replaced with "resolveRelativeUri".
