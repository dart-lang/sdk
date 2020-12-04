# Dart CLI tooling

```
A command-line utility for Dart development.

Usage: dart [<vm-flags>] <command|dart-file> [<arguments>]

Global options:
-h, --help                 Print this usage information.
-v, --verbose              Show additional command output.
    --version              Print the Dart SDK version.
    --enable-analytics     Enable anonymous analytics.
    --disable-analytics    Disable anonymous analytics.

Available commands:
  analyze   Analyze the project's Dart code.
  compile   Compile Dart to various formats.
  create    Create a new project.
  format    Idiomatically format Dart source code.
  pub       Work with packages.
  run       Run a Dart program.
  test      Run tests in this package.

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

[contributing]: https://github.com/dart-lang/sdk/blob/master/CONTRIBUTING.md
[design] https://github.com/dart-lang/sdk/blob/master/pkg/dartdev/doc/design.md
[tracker]: https://github.com/dart-lang/sdk/labels/area-dart-cli
