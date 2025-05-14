# Using plugins

This document describes how to enable an analyzer plugin. An analyzer plugin
can be enabled for a given package, so that the plugin can report diagnostics
(lints and warnings) and offer quick fixes. Plugins are enabled via the
`analysis_options.yaml` file under the top-level `plugins` section:

```yaml
plugins:
  my_plugin: ^1.0.0
```

Note: This is similar to how analyzer plugins are enabled in the [legacy][]
analyzer plugin system. However, in the legacy system, this `plugins` section
is listed under the top-level `analyzer` section. In the new analyzer plugin
system, `plugins` is a top-level section.

Individual plugins are listed similar to how dependencies are listed in a
`pubspec.yaml` file; they are listed as a key-value pair, with the package name
as the key. The value can either be

* a package version constraint, in which case the package is downloaded from
  https://pub.dev,
* a git dependency,
* an absolute path.

For example, while developing a plugin locally, it can be enabled as:

```yaml
plugins:
  my_plugin:
    path: /path/to/my_plugin
```

Note: after any change is made to the `plugins` section of an
`analysis_options.yaml` file, the Dart Analysis Server must be restarted to see
the effects.

[legacy]: https://github.com/dart-lang/sdk/blob/main/pkg/analyzer_plugin/doc/tutorial/tutorial.md

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