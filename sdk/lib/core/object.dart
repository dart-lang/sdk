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
 * [Implementing map
 * keys](https://www.dartlang.org/docs/dart-up-and-running/ch03.html#implementing-map-keys)
 * section of the [library
 * tour](http://www.dartlang.org/docs/dart-up-and-running/contents/ch03.html).
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
   * only if `this` and [other] are the same object.
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
   * The method should also be consistent over time, 
   * so whether two objects are equal should only change
   * if at least one of the objects was modified.
   *
   * If a subclass overrides the equality operator it should override
   * the [hashCode] method as well to maintain consistency.
   */
  external bool operator ==(other);

  /**
   * The hash code for this object.
   *
   * A hash code is a single integer which represents the state of the object
   * that affects [==] comparisons.
   * 
   * All objects have hash codes. 
   * The default hash code represents only the identity of the object, 
   * the same way as the default [==] implementation only considers objects
   * equal if they are identical (see [identityHashCode]).
   * 
   * If [==] is overridden to use the object state instead, 
   * the hash code must also be changed to represent that state. 
   * 
   * Hash codes must be the same for objects that are equal to each other
   * according to [==].
   * The hash code of an object should only change if the object changes
   * in a way that affects equality.
   * There are no further requirements for the hash codes.
   * They need not be consistent between executions of the same program
   * and there are no distribution guarantees.
   * 
   * Objects that are not equal are allowed to have the same hash code,
   * it is even technically allowed that all instances have the same hash code,
   * but if clashes happen too often, it may reduce the efficiency of hash-based
   * data structures like [HashSet] or [HashMap].
   * 
   * If a subclass overrides [hashCode], it should override the
   * [==] operator as well to maintain consistency.
   */
  external int get hashCode;

  /**
   * Returns a string representation of this object.
   */
  external String toString();

  /**
   * Invoked when a non-existent method or property is accessed.
   *
   * Classes can override [noSuchMethod] to provide custom behavior.
   *
   * If a value is returned, it becomes the result of the original invocation.
   *
   * The default behavior is to throw a [NoSuchMethodError].
   */
  external dynamic noSuchMethod(Invocation invocation);

  /**
   * A representation of the runtime type of the object.
   */
  external Type get runtimeType;
}
