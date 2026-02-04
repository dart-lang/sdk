# Using plugins

This document describes how to enable analyzer plugins. Analyzer plugins can
report diagnostics (lints and warnings) in an IDE and also at the command line
(with `dart analyze` or `flutter analyze`). Analyzer plugins can also offer
quick fixes and assists in an IDE. A set of analyzer plugins can be enabled for
a given package or [workspace][] via the `analysis_options.yaml` file, at the
root of the package or workspace source tree. Analyzer plugins cannot be
enabled, disabled, or otherwise specified or configured in a nested analysis
options file

Analyzer plugins are supported starting in Dart 3.10 (Flutter 3.38).

Analyzer plugins are specified in the top-level `plugins` section:

```yaml
plugins:
  my_plugin: ^1.0.0
```

[workspace]: https://dart.dev/tools/pub/workspaces

> [!NOTE]
> This is similar to how analyzer plugins are enabled in the [legacy][] analyzer
plugin system. However, in the legacy system, this `plugins` section is listed
under the top-level `analyzer` section. In the new analyzer plugin system,
`plugins` is a top-level section.

Individual plugins are listed similar to how dependencies are listed in a
`pubspec.yaml` file; they are listed as a key-value pair, with the package name
as the key. The value can either be

* a package version constraint, in which case the package is downloaded from
  https://pub.dev,
* an absolute path.

For example, while developing a plugin locally, it can be enabled as:

```yaml
plugins:
  my_plugin:
    path: /path/to/my_plugin
```

When the analysis server sees that a set of plugins is enabled, it creates a
synthetic package which depends on each plugin package, which is loaded into a
separate isolate of the analysis server process. It uses [`dart pub upgrade`][]
to resolve a compatible set of versions of the plugin packages and their
dependencies. Note that Dart 3.10 (Flutter 3.38) sets its own constraint on the
`analysis_server_plugin` package, `^0.3.0`. This may change with each release
of Dart and Flutter.

> [!NOTE]
> After any change is made to the `plugins` section of an
> `analysis_options.yaml` file, the Dart Analysis Server must be restarted to
> see the effects.

[legacy]: https://github.com/dart-lang/sdk/blob/main/pkg/analyzer_plugin/doc/tutorial/tutorial.md
[`dart pub upgrade`]: https://dart.dev/tools/pub/cmd/pub-upgrade

## Enabling a lint rule

A plugin can report two kinds of diagnostics: warnings and lints. Any warnings
that a plugin defines are enabled by default (like analyzer warnings). Any lint
rules that a plugin defines are disabled by default (like analyzer lint rules),
and must be explicitly enabled in analysis options. Lint rules are enabled
under the `diagnostics` section for a plugin:

```yaml
plugins:
  my_plugin:
    path: /path/to/my_plugin
    diagnostics:
      rule_1: true
      rule_2: true
      rule_3: false
```

In the configuration above, `rule_1` and `rule_2` are enabled. Additionally,
`rule_3` is disabled, which can be useful if an included analysis options file
explicitly enables the rule.

## Suppressing diagnostics

A diagnostic which is reported by a plugin can be suppressed with a comment. The
syntax is similar to suppressing an out-of-the-box warning or lint diagnostic
(see [the docs](https://dart.dev/tools/analysis#suppressing-diagnostics-for-a-file)).
To suppress a warning or lint named "some_code" in a plugin named "some_plugin,"
use a comment like the following:

```dart
// ignore: some_plugin/some_code

// ignore_for_file: some_plugin/some_code
```
