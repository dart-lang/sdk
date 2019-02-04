# dartanalyzer

Use _dartanalyzer_ to statically analyze your code at the command line,
checking for errors and warnings that are specified in the
[Dart Language Specification](https://www.dartlang.org/docs/spec/).
DartPad, code editors, and IDEs such as Android Studio and VS Code
use the same analysis engine that dartanalyzer uses.

## Basic usage

Run the analyzer from the top directory of the package.
Here's an example of testing a Dart file.

```
dartanalyzer bin/test.dart
```

## Options

The following are the most commonly used options for dartanalyzer:

* `--packages=`<br>
 Specify the path to the package resolution configuration file.
 For more information see
 [Package Resolution Configuration File](https://github.com/lrhn/dep-pkgspec/blob/master/DEP-pkgspec.md).
This option cannot be used with `--package-root`.

* `--package-warnings`<br>
  Show warnings not only for code in the specified .dart file and
  others in its library, but also for libraries imported with `package:`.

* `--options=`<br>
  Specify the path to an analysis options file.

* `--lints`<br>
  Show the results from the linter.

* `--no-hints`<br>
  Don't show hints for improving the code.

* `--ignore-unrecognized-flags`<br>
  Rather than printing the help message,
  ignore any unrecognized command-line flags.

* `--version`<br>
  Show the analyzer version.

* `-h` _or_ `--help`<br>
  Show all the command-line options.

The following are advanced options to use with dartanalyzer:

* `-b` _or_ `--batch`<br>
  Run in batch mode.

* `--dart-sdk=`<br>
  Specify the directory that contains the Dart SDK.

* `--fatal-warnings`<br>
  Except for type warnings, treat warnings as fatal.

* `--format=machine`<br>
  Produce output in a format suitable for parsing.

* `--url-mapping=libraryUri,/path/to/library.dart`<br>
  Tells the analyzer to use the specified library as the source for that
  particular import.

The following options are deprecated:

* `--package-root=`<br>
  **Deprecated.** Specify the directory to search for any libraries that are
  imported using `package:`. _This option is replaced as of Dart 1.12 with
  `--packages`._
