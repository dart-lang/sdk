# Linter for Dart

The Dart Linter package defines lint rules that identify and report on "lints" found in Dart code.  Linting is performed by the Dart
analysis server and the `dart analyze` command in the [Dart command-line tool](https://dart.dev/tools/dart-tool).

[![Lint Count](https://dart-lang.github.io/linter/lints/count-badge.svg)](https://dart-lang.github.io/linter/lints/)
[![Build Status](https://github.com/dart-lang/linter/workflows/linter/badge.svg)](https://github.com/dart-lang/linter/actions)
[![Coverage Status](https://coveralls.io/repos/dart-lang/linter/badge.svg)](https://coveralls.io/r/dart-lang/linter)
[![Pub](https://img.shields.io/pub/v/linter.svg)](https://pub.dev/packages/linter)

## Installing

The linter is bundled with the Dart [SDK](https://dart.dev/tools/sdk); if you have an updated Dart SDK already, you're done!

Alternatively, if you want to contribute to the linter or examine the source, clone the `linter` repo like this:

    $ git clone https://github.com/dart-lang/linter.git

## Usage

The linter gives you feedback to help you catch potential errors and keep your code in line with the published [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style/). Currently enforceable lint rules (or "lints") are catalogued [here][lints] and can be configured via an [analysis options file][options_file].  The linter is run from within the `dartanalyzer` [command-line tool](https://github.com/dart-lang/sdk/tree/master/pkg/analyzer_cli#dartanalyzer) shipped with the Dart SDK.  Assuming you have lints configured in an `analysis_options.yaml` file with these contents:

```yaml
linter:
  rules:
    - annotate_overrides
    - hash_and_equals
    - prefer_is_not_empty
```
you could lint your package like this:

    $ dartanalyzer --options analysis_options.yaml .
    
and see any violations of the `annotate_overrides`, `hash_and_equals`, and `prefer_is_not_empty` rules in the console.  To help you choose the rules you want to enable for your package, we have provided a [complete list of rules][lints].  For the lints that are enforced internally at Google, see [`package:pedantic`][package-pedantic].  For a set of rules corresponding to the [Effective Dart](https://dart.dev/guides/language/effective-dart) guide, see [`package:effective_dart`][package-effective-dart].

If a specific lint warning should be ignored, it can be flagged with a comment.  For example, 

```dart
   // ignore: avoid_as
   (pm as Person).firstName = 'Seth';
```

tells the `dartanalyzer` to ignore this instance of the `avoid_as` warning.

End-of-line comments are supported as well.  The following communicates the same thing:

```dart
   (pm as Person).firstName = 'Seth'; // ignore: avoid_as
```

To ignore a rule for an entire file, use the `ignore_for_file` comment flag.  For example,

```dart
// ignore_for_file: avoid_as

void main() {
  ...
  (pm as Person).firstName = 'Seth';
}
```

tells the `dartanalyzer` to ignore all occurences of the `avoid_as` warning in this file.

As lints are treated the same as errors and warnings by the analyzer, their severity can similarly be configured in an options file.  For example, an analysis options file that specifies

```yaml
linter:
  rules:
    - avoid_as
analyzer:
  errors:
    avoid_as: error
```  

tells the analyzer to treat `avoid_as` lints as errors.  For more on configuring analysis see the analysis option file [docs][options_file].

## Contributing

Feedback is greatly appreciated and contributions are welcome! Please read the
[contribution guidelines](CONTRIBUTING.md); mechanics of writing lints are covered [here](doc/WritingLints.MD).

## Features and bugs

Please file feature requests and bugs in the [issue tracker][tracker].

[tracker]: https://github.com/dart-lang/linter/issues
[lints]: https://dart-lang.github.io/linter/lints/
[package-pedantic]: https://github.com/dart-lang/pedantic/blob/master/lib/analysis_options.yaml
[package-effective-dart]: https://github.com/tenhobi/effective_dart
[options_file]: https://dart.dev/guides/language/analysis-options#the-analysis-options-file
