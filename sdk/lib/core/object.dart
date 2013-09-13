// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * The base class for all Dart objects.
 *
 * Because Object is the root of the Dart class hierarchy,
 * every other Dart class is a subclass of Object.
 *
 * When you define a class, you should override [toString]
 * to return a string describing an instance of that class.
 * You might also need to define [hashCode] and [==], as described in the
 * [Implementing map keys]
 * (http://www.dartlang.org/docs/dart-up-and-running/contents/ch03.html#ch03-implementing-map-keys)
 * section of the [library tour]
 * (http://www.dartlang.org/docs/dart-up-and-running/contents/ch03.html).
 */
class Object {
  /**
   * Creates a new [Object] instance.
   *
   * [Object] instances have no meaningful state, and are only useful
   * through their identity. An [Object] instance is equal to itself
   * only.
   */
  const Object();

  /**
   * The equality operator.
   *
   * The default behavior for all [Object]s is to return true if and
   * only if [:this:] and [other] are the same object.
   *
   * Override this method to specify a different equality relation on
   * a class. The overriding method must still be an equivalence relation.
   * That is, it must be:
   *
   *  * Total: It must return a boolean for all arguments. It should never throw
   *    or return `null`.
   *
   *  * Reflexive: For all objects `o`, `o == o` must be true.
   *
   *  * Symmetric: For all objects `o1` and `o2`, `o1 == o2` and `o2 == o1` must
   *    either both be true, or both be false.
   *
   *  * Transitive: For all objects `o1`, `o2`, and `o3`, if `o1 == o2` and
   *    `o2 == o3` are true, then `o1 == o3` must be true.
   *
   * The method should also be consistent over time, so equality of two objects
   * should not change over time, or at least only change if one of the objects
   * was modified.
   *
   * If a subclass overrides the equality operator it should override
   * the [hashCode] method as well to maintain consistency.
   */
  bool operator ==(other) => identical(this, other);

  /**
   * Get a hash code for this object.
   *
   * All objects have hash codes. Hash codes are guaranteed to be the
   * same for objects that are equal when compared using the equality
   * operator [:==:]. Other than that there are no guarantees about
   * the hash codes. They will not be consistent between runs and
   * there are no distribution guarantees.
   *
   * If a subclass overrides [hashCode] it should override the
   * equality operator as well to maintain consistency.
   */
  external int get hashCode;

  /**
   * Returns a string representation of this object.
   */
  external String toString();

  /**
   * [noSuchMethod] is invoked when users invoke a non-existant method
   * on an object. The name of the method and the arguments of the
   * invocation are passed to [noSuchMethod] in an [Invocation].
   * If [noSuchMethod] returns a value, that value becomes the result of
   * the original invocation.
   *
   * The default behavior of [noSuchMethod] is to throw a
   * [noSuchMethodError].
   */
  external dynamic noSuchMethod(Invocation invocation);

  /**
   * A representation of the runtime type of the object.
   */
  external Type get runtimeType;
}

