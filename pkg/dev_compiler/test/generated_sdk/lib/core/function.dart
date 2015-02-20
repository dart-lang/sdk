// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * The base class for all function types.
 *
 * A function value, or an instance of a class with a "call" method, is a
 * subtype of a function type, and as such, a subtype of [Function].
 */
abstract class Function {
  @patch
  static apply(Function function,
               List positionalArguments,
               [Map<Symbol, dynamic> namedArguments]) {
    return Primitives.applyFunction(
        function, positionalArguments,
        namedArguments == null ? null : _toMangledNames(namedArguments));
  }

  /**
   * Returns a hash code value that is compatible with `operator==`.
   */
  int get hashCode;

  /**
   * Test whether another object is equal to this function.
   *
   * System-created function objects are only equal to other functions.
   *
   * Two function objects are known to represent the same function if
   *
   * - It is the same object. Static and top-level functions are compile time
   *   constants when used as values, so referring to the same function twice
   *   always give the same object,
   * - or if they refer to the same member method extracted from the same object.
   *   Extracting a member method as a function value twice gives equal, but
   *   not necessarily identical, function values.
   *
   * Function expressions never give rise to equal function objects. Each time
   * a function expression is evaluated, it creates a new closure value that
   * is not known to be equal to other closures created by the same expression.
   *
   * Classes implementing `Function` by having a `call` method should have their
   * own `operator==` and `hashCode` depending on the object.
   */
  bool operator==(Object other);
}
