## 0.7.1

- README update to indicate that `dart:js_interop` should be preferred.

## 0.7.0

- Remove dependency on `dart:js`.
- Update SDK lower constraint to 3.1.0-66.0.dev.
- Update SDK upper constraint to 4.0.0.
- **Breaking Change**: Moved annotations to single location in
  `dart:_js_annotations`. This makes it easier to avoid collisions with
  `dart:js_interop`'s `@JS`, as you will now see a static error instead of it
  resolving in favor of the package definition. However, since this may result
  in breakages in previously working code, this is treated as a breaking change.

## 0.6.7

- Remove `example` link to discontinued example.

## 0.6.6

- Add `@JSExport` annotation for exporting Dart classes and `@staticInterop`
  mocking.
- Require Dart 2.19

## 0.6.5

- Populate the pubspec repository field.
- Add a dependency on `package:meta`.
- Add an experimental `@trustTypes` annotation.

## 0.6.4

- Includes `@staticInterop` to allow interop with native types from `dart:html`.

## 0.6.3

- Stable release for null safety.
- Update SDK constraints to `>=2.12.0 <3.0.0`.

## 0.6.2

- Improved documentation.

## 0.6.1+1

- Support Dart 2 final release.

## 0.6.1

- Add js_util library of utility methods to efficiently manipulate typed
  JavaScript interop objects in cases where the member name is not known
  statically.

## 0.6.0

- Version 0.6.0 is a complete rewrite of `package:js`.
