# native_api_lint

An analyzer plugin that lints **iOS/macOS API compatibility** for
[`ffigen`](https://pub.dev/packages/ffigen)-generated native interop bindings.

## Overview

When `ffigen` generates Dart FFI bindings from Objective-C headers, it can now
emit `@ExternalVersions` annotations (from
[`native_interop_annotation`](../native_interop_annotation)) that encode the
iOS/macOS availability windows of each API.

This plugin reads those annotations at analysis time and compares them against
your Flutter project's **minimum deployment target**, producing diagnostic
messages when:

1. **`api_not_available_on_min_target`** *(warning)* — A called API requires a
   newer OS version than your project targets. Calling it will crash on devices
   running your minimum OS version.

2. **`api_obsoleted_on_min_target`** *(error)* — A called API was removed in an
   OS version earlier than your minimum target. The API no longer exists.

3. **`api_deprecated_on_target`** *(info)* — A called API is deprecated (but
   still present) on your minimum deployment target. Consider migrating.

## Setup

### 1. Add the plugin to `analysis_options.yaml`

```yaml
analyzer:
  plugins:
    - native_api_lint

# Optional: manually override the auto-detected deployment target.
# By default the plugin reads ios/Podfile and ios/Runner.xcodeproj/project.pbxproj.
native_api_lint:
  ios_min: '14.0'    # override iOS minimum
  macos_min: '11.0'  # override macOS minimum
```

### 2. Re-run FFIgen

Run `dart run ffigen` with a version that supports `emit-availability-annotations`
to regenerate bindings with `@ExternalVersions` metadata.

### 3. Run analysis

```bash
flutter analyze
# or
dart analyze
```

Warnings like the following will appear at incompatible call sites:

```
warning • 'doSomething' requires ios 14.0+, but the project's minimum ios
deployment target is 13.0. • lib/my_feature.dart:42:5 •
api_not_available_on_min_target
```

## How deployment targets are resolved

The plugin resolves your minimum deployment target in this order:

| Priority | Source | Example |
|---|---|---|
| 1 | `analysis_options.yaml` override | `ios_min: '14.0'` |
| 2 | `ios/Podfile` | `platform :ios, '14.0'` |
| 3 | `ios/Runner.xcodeproj/project.pbxproj` | `IPHONEOS_DEPLOYMENT_TARGET = 14.0` |

For macOS, the same order applies using `macos/Podfile` and
`MACOSX_DEPLOYMENT_TARGET`.

## Suppressing diagnostics

Use the standard `// ignore:` mechanism:

```dart
// ignore: api_not_available_on_min_target
someNewApi(); // intentionally guarded with a runtime version check
```

## Architecture

```
native_interop_annotation  ←  shared contract
        ↑                              ↑
  ffigen (emits)            native_api_lint (reads)
                                       ↑
                            Flutter project (analysis_options.yaml)
```

## See also

- [native_interop_annotation](../native_interop_annotation) — defines `@ExternalVersions`
- [ffigen](https://pub.dev/packages/ffigen) — generates Dart bindings from ObjC/C headers
- [GitHub issue #63618](https://github.com/dart-lang/sdk/issues/63618) — original design discussion
