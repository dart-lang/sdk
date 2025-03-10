# Using plugins

This document describes how to enable an analyzer plugin. An analyzer plugin
can be enabled for a given package, so that the plugin can report diagnostics
(lints and warnings) and offer quick fixes. Plugins are enabled via the
`analysis_options.yaml` file under the top-level `plugins` section:

```
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

```
plugins:
  my_plugin:
    path: /path/to/my_plugin
```

Note: after any change is made to the `plugins` section of an
`analysis_options.yaml` file, the Dart Analysis Server must be restarted to see
the effects.

[legacy]: https://github.com/dart-lang/sdk/blob/main/pkg/analyzer_plugin/doc/tutorial/tutorial.md
