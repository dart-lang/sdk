# dartanalyzer

Use _dartanalyzer_ to statically analyze your code at the command line,
checking for errors and warnings that are specified in the
[Dart Language Specification](https://dart.dev/guides/language/spec).
DartPad, code editors, and IDEs such as Android Studio and VS Code
use the same analysis engine that dartanalyzer uses.

## Basic usage

Run the analyzer from the top directory of the package.
Here's an example of analyzing a Dart file.

```
dartanalyzer bin/test.dart
```

## Options

The following are the most commonly used options for dartanalyzer:

* `--packages=`

  Specify the path to the package resolution configuration file.
  For more information see
  [Package Resolution Configuration File](https://github.com/lrhn/dep-pkgspec/blob/master/DEP-pkgspec.md).

* `--package-warnings`

  Show warnings not only for code in the specified .dart file and
  others in its library, but also for libraries imported with `package:`.

* `--options=`

  Specify the path to an analysis options file.

* `--[no-]lints`

  Show the results from the linter.

* `--[no-]hints`

  Don't show hints for improving the code.

* `--version`

  Show the analyzer version.

* `-h` _or_ `--help`

  Show all of the command-line options.

See the[Customizing static analysis
guide](https://dart.dev/guides/language/analysis-options) for further ways to
customize how dartanalyzer performs static analysis, and how it reports its
findings.

The following are advanced options to use with dartanalyzer:

* `--dart-sdk=`

  Specify the directory that contains the Dart SDK.

* `--fatal-warnings`

  Except for type warnings, treat warnings as fatal.

* `--format=machine`

  Produce output in a format suitable for parsing.

* `--ignore-unrecognized-flags`

  Rather than printing the help message, ignore any unrecognized command-line
  flags.

* `--url-mapping=libraryUri,/path/to/library.dart`

  Use the specified library as the source for that particular import.
