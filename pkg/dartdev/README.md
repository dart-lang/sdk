# Dart CLI tooling

```
A command-line utility for Dart development.

Usage: dart <command|dart-file> [arguments]

Global options:
-v, --verbose               Show additional command output.
    --version               Print the Dart SDK version.
    --enable-analytics      Enable analytics.
    --disable-analytics     Disable analytics.
    --suppress-analytics    Disallow analytics for this `dart *` run without changing the analytics configuration.
-h, --help                  Print this usage information.

Available commands:
  analyze    Analyze Dart code in a directory.
  compile    Compile Dart to various formats.
  create     Create a new Dart project.
  devtools   Open DevTools (optionally connecting to an existing application).
  doc        Generate API documentation for Dart projects.
  fix        Apply automated fixes to Dart source code.
  format     Idiomatically format Dart source code.
  info       Show diagnostic information about the installed tooling.
  pub        Work with packages.
  run        Run a Dart program.
  test       Run tests for a project.

Run "dart help <command>" for more information about a command.
See https://dart.dev/tools/dart-tool for detailed documentation.
```

## Contributing

If you'd like to contribute to the Dart CLI tool, please start by reading the
[contribution guidelines][contributing] for the Dart project. Then familiarize
yourself with the [design principles][design] that guide this tool's UX.

## Features and bugs

Please file feature requests and bugs in the Dart SDK [issue tracker][tracker]
with label `area-dart-cli`.

[contributing]: https://github.com/dart-lang/sdk/blob/main/CONTRIBUTING.md
[design]: https://github.com/dart-lang/sdk/blob/main/pkg/dartdev/doc/design.md
[tracker]: https://github.com/dart-lang/sdk/labels/area-dart-cli
