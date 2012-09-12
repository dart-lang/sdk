// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * An [Expando] allows adding new properties to objects.
 */
class Expando<T> {

  /**
   * The name of the this [Expando] as passed to the constructor. If
   * no name was passed to the constructor, the name is [null].
   */
  final String name;

  /**
   * Creates a new [Expando]. The optional name is only used for
   * debugging purposes and creating two different (non-const)
   * [Expando]s with the same name yields two [Expando]s that work on
   * different properties of the objects they are used on.
   */
  const Expando([String this.name]);

  /**
   * Expando toString method override.
   */
  String toString() => "Expando:$name";

  /**
   * Gets the value of this [Expando]'s property on the given
   * object. If the object hasn't been expanded, the method returns
   * [null].
   */
  external T operator [](Object object);

  /**
   * Sets the value of this [Expando]'s property on the given
   * object. Properties can effectively be removed again by setting
   * their value to null.
   */
  external void operator []=(Object object, T value);

}
