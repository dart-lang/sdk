// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Behavior variations of the current Dart execution.
///
/// Dart compilers vary the behavior of the compiled code in certain predictable
/// ways depending on the target platform or optimization flags, for example.
///
/// When writing SDK or language tests, the tests should be aware of, and
/// account for, those variations.
///
/// The properties in this library are used to narrow expectations in SDK tests.
/// That helps preserve test coverage in the presence of behavior variations in
/// Dart implementations and testing configurations.
///
/// Some variations in behavior are language compliant:
///
///   * [number semantics][1] change when targeting JavaScript
///   * some features have modalities (whether assertions are enabled, weak vs
///     sound null safety),
///   * some compilers support a subset of SDK libraries (for example, `dart:io`
///     on native platforms), and
///   * some behaviors are purposely unspecified (such as string representation
///     of types, which can change in the presence of minification
///     optimizations).
///
/// Some variations can result from unsafe optimizations. These are deviations
/// from the language or library contracts. Typically, this is done by backends
/// like dart2js or dart2wasm that run on a sandboxed environment which limits
/// the consequences of an erroneous optimization. Examples include:
///
///   * omitting covariant and dynamic parameter checks
///   * omitting implicit or explicit downcasts
///   * bypassing checks in library code, like range checks when accessing
///     native arrays in JavaScript.
///
/// Regardless of the reason, variations are deliberate and should be accounted
/// for in testing. Each behavior in this library is based on an underlying
/// variation in an existing Dart implementation.
///
/// Note: A coarse-grain alternative for each of these is also available in the
/// `test_runner` infrastructure for narrowing expectations on entire test
/// files.
///
/// [1]: https://dart.dev/guides/language/numbers "Numbers in Dart"
// TODO(54798): include conditions for VM/AOT/Wasm backends (current
// definitions only reflect variations under dart2js and DDC compilers).
// TODO(54798): update this dartdoc to also have a link to the standard
// reference of variations when it becomes available in the SDK wiki.
library;

/// Whether `assert`s are enabled.
// TODO: If information can be made available as a constant, use that.
// (For example if we introduce a compilation-environment entry for it.)
final bool enabledAsserts = (() {
  bool result = false;
  assert(result = true);
  return result;
})();

/// Whether the program is running without sound null safety.
const bool unsoundNullSafety = <Null>[] is List<Object>;

/// Whether the program is running with JavaScript [number semantics][1].
///
/// In code compiled to JavaScript, Dart integers are represented by JavaScript
/// numbers, which have different ranges and behavior than native integers.
///
/// For example, using JavaScript numbers, an `int` value like `1` also
/// implements `double` and is the same object as `1.0`. In native numbers,
/// those values are two different objects, and integers do not implement
/// `double`.
///
/// _Note: We do not use the term web-numbers because the Dart Wasm backend is
/// considered a web backend, but uses native number semantics._
///
/// [1]: https://dart.dev/guides/language/numbers "Numbers in Dart"
const bool jsNumbers = identical(1, 1.0);

/// Whether [Type.toString] exposes the source names of types.
///
/// If so, the strings are readable and can be used to match certain
/// expectations. Typically this is not the case in production configurations
/// that enable minification, like `dart compile js -O2` and `dart compile exe`.
bool get readableTypeStrings =>
    !const bool.fromEnvironment('dart.tool.dart2js.minify');

/// Whether runtime parameter type checks are enforced.
///
/// Runtime parameter type checks include both covariant parameter checks,
/// either from generics or declared as `covariant`, and parameter checks of
/// dynamic function invocations through `dynamic` or `Function`.
///
/// For example, this code should fail a covariant parameter check:
///
/// ```dart
/// List<Object> list = <String>[];
/// list.add(1);
/// ```
///
/// And this code should fail a dynamic invocation parameter type check:
///
/// ```dart
/// class A {
///    m(int x) {}
/// }
/// (A() as dynamic).m("value");
/// ```
bool get checkedParameters =>
    !const bool.fromEnvironment('dart.tool.dart2js.types:trust');

/// Whether implicit downcasts from `dynamic` are typed checked at runtime.
///
/// The language allows an expression of type `dynamic` to be used
/// where any other type is required, by doing a runtime check that
/// the value has the required type.
/// This value is `false` when that runtime check is omitted.
///
/// For example, this code should fail with an invalid implicit cast:
/// ```dart
/// dynamic d = 3; String s = d;
/// ```
bool get checkedImplicitDowncasts =>
    !const bool.fromEnvironment('dart.tool.dart2js.types:trust');

/// Whether explicit casts are type checked at runtime.
///
/// An expression like `e as String` should perform a runtime check that the
/// value of `e` implements `String`.
/// This value is `false` when that runtime check is omitted, and the runtime
/// code will just use the value of `e` assuming it to be a string.
///
/// For example, this code should fail the explicit cast when the integer `3` is
/// checked for being a `String`:
///
/// ```dart
/// Object o = 3;
/// o as String;
/// ```
bool get checkedExplicitCasts => true;
