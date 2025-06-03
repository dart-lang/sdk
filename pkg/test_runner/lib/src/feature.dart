// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// A capability that a Dart implementation may or may not provide that a test
/// may require.
///
/// Each `TestConfiguration` specifies the set of features it supports. A test
/// can have a "// Requirements" comment indicating the names of features it
/// requires. If a test requires a feature not supported by the current
/// configution, the test runner automatically skips it.
class Feature {
  /// Enforces that explicit casts from `as` expressions are type checked at
  /// runtime.
  static const checkedExplicitCasts = Feature._("checked-explicit-casts");

  /// Enforces that implicit downcasts from `dynamic` are typed checked at
  /// runtime.
  static const checkedImplicitDowncasts =
      Feature._("checked-implicit-downcasts");

  /// Enforces runtime parameter type checks.
  ///
  /// These checks include both covariant parameter checks, either from generics
  /// or declared as `covariant`, and parameter checks of dynamic function
  /// invocations through `dynamic` or `Function`.
  static const checkedParameters = Feature._("checked-parameters");

  /// Supports JavaScript number semantics.
  ///
  /// In code compiled to JavaScript, Dart integers are represented by
  /// JavaScript numbers, which have different ranges and behavior than native
  /// integers.
  static const jsNumbers = Feature._("js-numbers");

  /// Supports native number semantics.
  static const nativeNumbers = Feature._("native-numbers");

  /// Expects [Type.toString] to show the original type name and original
  /// names in function type named parameters.
  static const readableTypeStrings = Feature._("readable-type-strings");

  static const all = [
    checkedExplicitCasts,
    checkedImplicitDowncasts,
    checkedParameters,
    jsNumbers,
    nativeNumbers,
    readableTypeStrings,
  ];

  final String name;

  const Feature._(this.name);

  @override
  String toString() => name;
}
