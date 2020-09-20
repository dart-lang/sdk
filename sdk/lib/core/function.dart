// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * The base class for all function types.
 *
 * The run-time type of a function object is subtype of a function type,
 * and as such, a subtype of [Function].
 */
abstract class Function {
  /**
   * Dynamically call [function] with the specified arguments.
   *
   * Acts the same as calling function with positional arguments
   * corresponding to the elements of [positionalArguments] and
   * named arguments corresponding to the elements of [namedArguments].
   *
   * This includes giving the same errors if [function] isn't callable or
   * if it expects different parameters.
   *
   * Example:
   * ```
   * Function.apply(foo, [1,2,3], {#f: 4, #g: 5});
   * ```
   *
   * gives exactly the same result as
   * ```
   * foo(1, 2, 3, f: 4, g: 5).
   * ```
   *
   * If [positionalArguments] is null, it's considered an empty list.
   * If [namedArguments] is omitted or null, it is considered an empty map.
   */
  external static apply(Function function, List<dynamic>? positionalArguments,
      [Map<Symbol, dynamic>? namedArguments]);

  /**
   * Returns a hash code value that is compatible with `operator==`.
   */
  int get hashCode;

  /**
   * Test whether another object is equal to this function.
   *
   * Function objects are only equal to other function objects
   * (an object satisfying `object is Function`),
   * and never to non-function objects.
   *
   * Some function objects are considered equal by `==`
   * because they are recognized as representing the "same function":
   *
   * - It is the same object. Static and top-level functions are compile time
   *   constants when used as values, so referring to the same function twice
   *   always give the same object, as does referring to a local function
   *   declaration twice in the same scope where it was declared.
   * - if they refer to the same member method extracted from the same object.
   *   Repeatedly extracting an instance method of an object as a function value
   *   gives equal, but not necessarily identical, function values.
   *
   * Different evaluations of function literals
   * never give rise to equal function objects.
   * Each time a function literal is evaluated,
   * it creates a new function value that is not equal to any other function
   * value, not even ones created by the same expression.
   */
  bool operator ==(Object other);
}
