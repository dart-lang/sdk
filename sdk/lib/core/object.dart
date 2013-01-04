// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * Everything in Dart is an [Object].
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
   * invocation are passed to [noSuchMethod] in an [InvocationMirror].
   * If [noSuchMethod] returns a value, that value becomes the result of
   * the original invocation.
   *
   * The default behavior of [noSuchMethod] is to throw a
   * [noSuchMethodError].
   */
  external dynamic noSuchMethod(InvocationMirror invocation);

  /**
   * A representation of the runtime type of the object.
   */
  external Type get runtimeType;
}

