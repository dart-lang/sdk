// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * An [Expando] allows adding new properties to objects.
 *
 * Does not work on numbers, strings, booleans or null.
 *
 * An `Expando` does not hold on to the added property value after an object
 * becomes inaccessible.
 *
 * Since you can always create a new number that is identical to an existing
 * number, it means that an expando property on a number could never be
 * released. To avoid this, expando properties cannot be added to numbers.
 * The same argument applies to strings, booleans and null, which also have
 * literals that evaluate to identical values when they occur more than once.
 *
 * There is no restriction on other classes, even for compile time constant
 * objects. Be careful if adding expando properties to compile time constants,
 * since they will stay alive forever.
 */
class Expando<T> {
  /**
   * The name of the this [Expando] as passed to the constructor. If
   * no name was passed to the constructor, the name is [:null:].
   */
  final String name;

  /**
   * Creates a new [Expando]. The optional name is only used for
   * debugging purposes and creating two different [Expando]s with the
   * same name yields two [Expando]s that work on different properties
   * of the objects they are used on.
   */
  external Expando([String name]);

  /**
   * Expando toString method override.
   */
  String toString() => "Expando:$name";

  /**
   * Gets the value of this [Expando]'s property on the given
   * object. If the object hasn't been expanded, the method returns
   * [:null:].
   *
   * The object must not be a number, a string, a boolean or null.
   */
  external T operator [](Object object);

  /**
   * Sets the value of this [Expando]'s property on the given
   * object. Properties can effectively be removed again by setting
   * their value to null.
   *
   * The object must not be a number, a string, a boolean or null.
   */
  external void operator []=(Object object, T value);
}
