# Linter for Dart

The Dart Linter package defines lint rules that identify and report on "lints" found in Dart code.  Linting is performed by the Dart
analysis server and the `dart analyze` command in the [Dart command-line tool][dart_cli].

## Installing

The linter is bundled with the Dart [SDK](https://dart.dev/tools/sdk); if you have an updated Dart SDK already, you're done!

## Usage

The linter gives you feedback to help you catch potential errors and keep your code in line with the published
[Dart Style Guide][style_guide]. Enforceable lint rules (or "lints") are cataloged [here][lints] and can be configured via an
[analysis options file][options_file].  The linter is run from within the `dart analyze` [command-line tool][analyzer_cli] shipped with the
Dart SDK.  Assuming you have lints configured in an `analysis_options.yaml` file at the root of your project with these contents:

```yaml
linter:
  rules:
    - annotate_overrides
    - hash_and_equals
    - prefer_is_not_empty
```
you could lint your package like this:

    $ dart analyze .

and see any violations of the `annotate_overrides`, `hash_and_equals`, and `prefer_is_not_empty` rules in the console.
To help you choose the rules you want to enable for your package, we have provided a [complete list of rules][lints]
with lints recommended by the Dart team collected in [`package:lints`][package-dart-lints]. Lints recommended for Flutter apps, packages,
and plugins are documented in [`package:flutter_lints`][package-flutter-lints].

If a specific lint warning should be ignored, it can be flagged with a comment.  For example,

```dart
   // ignore: camel_case_types
   class whyOhWhy { }
```

tells the Dart analyzer to ignore this instance of the `camel_case_types` warning.

End-of-line comments are supported as well.  The following communicates the same thing:

```dart
   class whyOhWhy { // ignore: camel_case_types
```

To ignore a rule for an entire file, use the `ignore_for_file` comment flag.  For example,

```dart
// ignore_for_file: camel_case_types

...

class whyOhWhy { }
```

tells the Dart analyzer to ignore all occurrences of the `camel_case_types` warning in this file.

As lints are treated the same as errors and warnings by the analyzer, their severity can similarly be configured in an options file.  For
example, an analysis options file that specifies

```yaml
linter:
  rules:
    - camel_case_types
analyzer:
  errors:
    camel_case_types: error
```

tells the analyzer to treat `camel_case_types` lints as errors.  For more on configuring analysis see the analysis option file [docs][options_file].

## Contributing

Feedback is greatly appreciated and contributions are welcome! Please read the
[contribution guidelines](CONTRIBUTING.md); mechanics of writing lints are covered [here](doc/writing-lints.md).

## Features and bugs

Please file feature requests and bugs in the [issue tracker][tracker].

[analyzer_cli]: https://dart.dev/tools/dart-analyze
[dart_cli]: https://dart.dev/tools/dart-tool
[effective_dart]: https://dart.dev/effective-dart
[lints]: https://dart.dev/lints
[options_file]: https://dart.dev/guides/language/analysis-options#the-analysis-options-file
[package-dart-lints]: https://github.com/dart-lang/lints
[package-flutter-lints]: https://github.com/flutter/packages/tree/main/packages/flutter_lints
[style_guide]: https://dart.dev/effective-dart/style
[tracker]: https://github.com/dart-lang/linter/issues
