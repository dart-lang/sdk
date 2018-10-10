// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * The reserved words `true` and `false` denote objects that are the only two
 * instances of this class.
 *
 * It is a compile-time error for a class to attempt to extend or implement
 * bool.
 */
@pragma("vm:entry-point")
class bool {
  /**
   * Returns the boolean value of the environment declaration [name].
   *
   * The boolean value of the declaration is `true` if the declared value is
   * the string `"true"`, and `false` if the value is `"false"`.
   *
   * In all other cases, including when there is no declaration for `name`,
   * the result is the [defaultValue].
   *
   * The result is the same as would be returned by:
   * ```dart
   * (const String.fromEnvironment(name) == "true")
   *     ? true
   *     : (const String.fromEnvironment(name) == "false")
   *         ? false
   *         : defaultValue
   * ```
   * Example:
   * ```dart
   * const loggingFlag = const bool.fromEnvironment("logging");
   * ```
   * If you want to use a different truth-string than `"true"`, you can use the
   * [String.fromEnvironment] constructor directly:
   * ```dart
   * const isLoggingOn = (const String.fromEnvironment("logging") == "on");
   * ```
   */
  // The .fromEnvironment() constructors are special in that we do not want
  // users to call them using "new". We prohibit that by giving them bodies
  // that throw, even though const constructors are not allowed to have bodies.
  // Disable those static errors.
  //ignore: const_constructor_with_body
  //ignore: const_factory
  external const factory bool.fromEnvironment(String name,
      {bool defaultValue: false});

  external int get hashCode;

  /// The logical conjunction ("and") of this and [other].
  ///
  /// Returns `true` if both this and [other] are `true`, and `false` otherwise.
  //TODO(lrn): Remove "as bool" in Dart 2.
  bool operator &(bool other) => (other as bool) && this;

  /// The logical disjunction ("inclusive or") of this and [other].
  ///
  /// Returns `true` if either this or [other] is `true`, and `false` otherwise.
  bool operator |(bool other) => (other as bool) || this;

  /// The logical exclusive disjunction ("exclusive or") of this and [other].
  ///
  /// Returns whether this and [other] are neither both `true` nor both `false`.
  bool operator ^(bool other) => !(other as bool) == this;

  /**
   * Returns either `"true"` for `true` and `"false"` for `false`.
   */
  String toString() {
    return this ? "true" : "false";
  }
}
