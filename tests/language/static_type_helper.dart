// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Ensures a context type of [T] for the operand.
void context<T>(T x) {}

/// Captures the context type of the call and returns the same type.
///
/// Can be used to check the context type as:
/// ```dart
/// int x = contextType(1 /* valid value */)..expectStaticType<Exactly<int>>;
/// ```
T contextType<T>(Object result) => result as T;

extension StaticType<T> on T {
  /// Check the static type.
  ///
  /// Use as follows (assuming `e` has static type `num`):
  /// ```dart
  ///   e.expectStaticType<Exactly<num>>()  // No context type.
  ///   e.expectStaticType<SubtypeOf<Object>>()  // No context type.
  ///   e.expectStaticType<SupertypeOf<int>>()  // No context type.
  /// ```
  /// or
  /// ```dart
  ///   e..expectStaticType<Exactly<num>>()  // Preserve context type.
  ///   e..expectStaticType<SubtypeOf<Object>>()  // Preserve context type.
  ///   e..expectStaticType<SupertypeOf<int>>()  // Preserve context type.
  /// ```
  /// This will be a *compile-time error* if the static type is not
  /// as required by the constraints type (the one passed to [Exactly],
  /// [SubtypeOf] or [SupertypeOf].)
  T expectStaticType<R extends Exactly<T>>() {
    return this;
  }
}

/// Use with [StaticType.expectStaticType] to expect precisely the type [T].
///
/// Example use:
/// ```dart
/// "abc".expectStaticType<Exactly<String>>();
/// ```
typedef Exactly<T> = T Function(T);

/// Use with [StaticType.expectStaticType] to expect a subtype of [T].
///
/// Example use:
/// ```dart
/// num x = 1;
/// x.expectStaticType<SubtypeOf<Object>>();
/// ```
typedef SubtypeOf<T> = Never Function(T);

/// Use with [StaticType.expectStaticType] to expect a supertype of [T].
///
/// Example use:
/// ```dart
/// num x = 1;
/// x.expectStaticType<SupertypeOf<int>>();
/// ```
typedef SupertypeOf<T> = T Function(Object?);

/// Checks that an expression is assignable to [T1], [T2] and [Object].
///
/// This ensures that the static type of the expression is either dynamic,
/// Never, or a type assignable to both [T1] and [T2], and if those are
/// unrelated, it must be an intersection type.
void checkIntersectionType<T1, T2>(T1 v1, T2 v2, Object v3) {}
