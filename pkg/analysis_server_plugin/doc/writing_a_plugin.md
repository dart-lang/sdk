# Writing a plugin

This document describes how to write an analyzer plugin, to provide custom
static analysis, or to offer custom quick fixes in an IDE.

## The pubspec file

An analyzer plugin is a Dart package, so let's start with the `pubspec.yaml` file:

```yaml
name: test_analyzer_plugin
version: 0.0.1

environment:
  sdk: ^3.7.0

dependencies:
  analysis_server_plugin: ^0.2.2
  analyzer: ^8.0.0
```

There is nothing special about this pubspec; note that we need a dependency on
the `analysis_server_plugin` package, and on the `analyzer` package, supporting
at least 8.0.0. The version of the analyzer package needs to move lockstep with
the Dart SDK. For Dart 3.10.0-75.1.beta, `^8.0.0` is a good version constraint.

## The main Dart file

One source file is required, at `lib/main.dart`. Here is the basic layout:

```dart
import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';

final plugin = SimplePlugin();

class SimplePlugin extends Plugin {
  @override
  void register(PluginRegistry registry) {
    // Here we register analysis rules, quick fixes, and quick assists.
  }
}
```

Here we have a class, `SimplePlugin`, which extends the `Plugin` class from the
`analysis_server_plugin` package. This class has one method that we override:
`register`. In the `register` method, we can register analysis rules, quick
fixes, and quick assists (`CorrectionProducer`s). See these other guides for
details:

* [writing rules][]
* [writing fixes][]
* [writing assists][]
* [testing rules][]

Additionally, we provide a top-level variable in this file called `plugin`,
which is an instance of our `SimplePlugin` class. When a running instance of
the Dart Analysis Server needs to use this analyzer plugin, it generates some
code that needs to _import_ this `lib/main.dart` file, and that references this
`plugin` top-level variable.

# Debugging a plugin

If a plugin is not behaving as expected (for example, warnings are not
appearing in the IDE), you can check the [analyzer diagnostics pages][]. If the
plugin isolate has crashed, the "plugins" screen will display the crash.

`print` cannot be used in plugin code to debug. Instead, writing to a log file
can help in debugging plugin code.

[writing rules]: https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_rules.md
[writing fixes]: https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_fixes.md
[writing assists]: https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_assists.md
[testing rules]: https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/testing_rules.md
[analyzer diagnostics pages]: https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server/doc/tutorial/instrumentation.md#open-the-analyzer-diagnostics-pages
