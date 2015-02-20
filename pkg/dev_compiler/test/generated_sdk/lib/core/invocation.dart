// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * Representation of the invocation of a member on an object.
 *
 * This is the type of objects passed to [Object.noSuchMethod] when
 * an object doesn't support the member invocation that was attempted
 * on it.
 */
abstract class Invocation {
  /** The name of the invoked member. */
  Symbol get memberName;

  /**
   * An unmodifiable view of the positional arguments of the call.
   *
   * If the member is a getter, the positional arguments is empty.
   */
  List get positionalArguments;

  /**
   * An unmodifiable view of the named arguments of the call.
   *
   * If the member is a getter, setter or operator, the named arguments
   * is empty.
   */
  Map<Symbol, dynamic> get namedArguments;

  /** Whether the invocation was a method call. */
  bool get isMethod;

  /**
   * Whether the invocation was a getter call.
   * If so, both types of arguments is empty.
   */
  bool get isGetter;

  /**
   * Whether the invocation was a setter call.
   *
   * If so, [arguments] has exactly one positonal argument,
   * and [namedArguments] is empty.
   */
  bool get isSetter;

  /** Whether the invocation was a getter or a setter call. */
  bool get isAccessor => isGetter || isSetter;
}
