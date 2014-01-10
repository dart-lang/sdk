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
   *       Map<Symbol, dynamic> namedArguments = new Map<Symbol, dynamic>();
   *       namedArguments[const Symbol("f")] = 4;
   *       namedArguments[const Symbol("g")] = 5;
   *       Function.apply(foo, [1,2,3], namedArguments);
   *
   * gives exactly the same result as
   *       foo(1, 2, 3, f: 4, g: 5).
   *
   * If [positionalArguments] is null, it's considered an empty list.
   * If [namedArguments] is omitted or null, it is considered an empty map.
   */
  external static apply(Function function,
                        List positionalArguments,
                        [Map<Symbol, dynamic> namedArguments]);
}
