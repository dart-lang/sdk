## What are Flutter pinned packages?

Flutter pinned packages are a set of packages that are pinned by the Flutter SDK to specific versions. Some examples are `package:characters` (pinned by `package:flutter`), `package:collection` (also pinned by `package:flutter`), and `package:path` (pinned by `package:flutter_test`).

To see the current list of pinned packages of the Flutter SDK at head, see the ‘dependencies’ section of the following pubspecs:

- https://github.com/flutter/flutter/blob/master/packages/flutter/pubspec.yaml
- https://github.com/flutter/flutter/blob/master/packages/flutter_test/pubspec.yaml
- https://github.com/flutter/flutter/blob/master/packages/flutter_localizations/pubspec.yaml

If you’re not using one of the above packages (e.g. `package:flutter_localizations`) then you won’t be affected by its package pinning.

## Why does Flutter pin package versions?

By pinning its dependencies it is ensured the future release of a new package-version will not break apps made with an old Flutter SDK.

## How does the pinning affect me?

If you’re developing a Flutter app, your app can only use the specific version of a package that Flutter has pinned. If you have a direct dependency on a pinned package, your pubspec constraint must support the version pinned by Flutter. E.g. if Flutter has pinned `package:path` to `1.8.3`, your pubspec constraint must support that version:

```yaml
dependencies:
  path: ^1.8.0
```

Similarly, if you’re using a package which itself has a dependency on a pinned package, that package needs to support the pinned version (i.e. your transitive dependencies also need to support the pinned version).

Generally people experience issues with pinning if their pubspec constraints don’t support the pinned Flutter version, or - transitively - if one of their package dependencies don’t support the pinned version.

## What are some workarounds?

### An immediate dependency doesn’t resolve

Widen your constraint on the package in question (e.g. change a `>=1.7.0 < 1.8.0` constraint on package:path to `^1.8.0`).

### I see issues through one of my dependencies

The package you’re using needs to widen its constraint on the pinned package. Either you need to update your dependency to bring in a new version of the package, or, that package needs to publish a new version that supports the pinned package version. If a version of the package isn’t available which supports the pinned version, try visiting the issue tracker of the dependency to let them know about the issue.

### I see issues through one of my dependencies but they can’t immediately release a new version

As a fallback solution, you can specify a [dependency override](https://dart.dev/tools/pub/dependencies#dependency-overrides) in your own pubspec. This will tell pub to use a specific version of a package whether or not it’s compatible with the other packages you’re using.

```yaml
dependency_overrides:
  foo: 1.8.3
```

Note that you’re now consuming a version of ‘foo’ that not all of your other dependencies have been tested with; you may see analysis or runtime issues as a result (this should be considered a short-term solution).
