// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/// The base class for all Dart objects exception `null`.
///
/// Because `Object` is a root of the non-nullable Dart class hierarchy,
/// every other non-`Null` Dart class is a subclass of `Object`.
///
/// When you define a class, you should consider overriding [toString]
/// to return a string describing an instance of that class.
/// You might also need to define [hashCode] and [operator ==], as described in the
/// [Implementing map keys](https://dart.dev/guides/libraries/library-tour#implementing-map-keys)
/// section of the [library tour](https://dart.dev/guides/libraries/library-tour).
@pragma("vm:entry-point")
class Object {
  /// Creates a new [Object] instance.
  ///
  /// [Object] instances have no meaningful state, and are only useful
  /// through their identity. An [Object] instance is equal to itself
  /// only.
  @pragma("vm:recognized", "other")
  const Object();

  /// The equality operator.
  ///
  /// The default behavior for all [Object]s is to return true if and
  /// only if this object and [other] are the same object.
  ///
  /// Override this method to specify a different equality relation on
  /// a class. The overriding method must still be an equivalence relation.
  /// That is, it must be:
  ///
  ///  * Total: It must return a boolean for all arguments. It should never throw.
  ///
  ///  * Reflexive: For all objects `o`, `o == o` must be true.
  ///
  ///  * Symmetric: For all objects `o1` and `o2`, `o1 == o2` and `o2 == o1` must
  ///    either both be true, or both be false.
  ///
  ///  * Transitive: For all objects `o1`, `o2`, and `o3`, if `o1 == o2` and
  ///    `o2 == o3` are true, then `o1 == o3` must be true.
  ///
  /// The method should also be consistent over time,
  /// so whether two objects are equal should only change
  /// if at least one of the objects was modified.
  ///
  /// If a subclass overrides the equality operator, it should override
  /// the [hashCode] method as well to maintain consistency.
  external bool operator ==(Object other);

  /// The hash code for this object.
  ///
  /// A hash code is a single integer which represents the state of the object
  /// that affects [operator ==] comparisons.
  ///
  /// All objects have hash codes.
  /// The default hash code implemented by [Object]
  /// represents only the identity of the object,
  /// the same way as the default [operator ==] implementation only considers objects
  /// equal if they are identical (see [identityHashCode]).
  ///
  /// If [operator ==] is overridden to use the object state instead,
  /// the hash code must also be changed to represent that state,
  /// otherwise the object cannot be used in hash based data structures
  /// like the default [Set] and [Map] implementations.
  ///
  /// Hash codes must be the same for objects that are equal to each other
  /// according to [operator ==].
  /// The hash code of an object should only change if the object changes
  /// in a way that affects equality.
  /// There are no further requirements for the hash codes.
  /// They need not be consistent between executions of the same program
  /// and there are no distribution guarantees.
  ///
  /// Objects that are not equal are allowed to have the same hash code.
  /// It is even technically allowed that all instances have the same hash code,
  /// but if clashes happen too often,
  /// it may reduce the efficiency of hash-based data structures
  /// like [HashSet] or [HashMap].
  ///
  /// If a subclass overrides [hashCode], it should override the
  /// [operator ==] operator as well to maintain consistency.
  external int get hashCode;

  /// A string representation of this object.
  ///
  /// Some classes have a default textual representation,
  /// often paired with a static `parse` function (like [int.parse]).
  /// These classes will provide the textual representation as
  /// their string represetion.
  ///
  /// Other classes have no meaningful textual representation
  /// that a program will care about.
  /// Such classes will typically override `toString` to provide
  /// useful information when inspecting the object,
  /// mainly for debugging or logging.
  external String toString();

  /// Invoked when a non-existent method or property is accessed.
  ///
  /// A dynamic member invocation can attempt to call a member which
  /// doesn't exist on the receiving object. Example:
  /// ```dart
  /// dynamic object = 1;
  /// object.add(42); // Statically allowed, run-time error
  /// ```
  /// This invalid code will invoke the `noSuchMethod` method
  /// of the integer `1` with an [Invocation] representing the
  /// `.add(42)` call and arguments (which then throws).
  ///
  /// Classes can override [noSuchMethod] to provide custom behavior
  /// for such invalid dynamic invocations.
  ///
  /// A class with a non-default [noSuchMethod] invocation can also
  /// omit implementations for members of its interface.
  /// Example:
  /// ```dart
  /// class MockList<T> implements List<T> {
  ///   noSuchMethod(Invocation invocation) {
  ///     log(invocation);
  ///     super.noSuchMethod(invocation); // Will throw.
  ///   }
  /// }
  /// void main() {
  ///   MockList().add(42);
  /// }
  /// ```
  /// This code has no compile-time warnings or errors even though
  /// the `MockList` class has no concrete implementation of
  /// any of the `List` interface methods.
  /// Calls to `List` methods are forwarded to `noSuchMethod`,
  /// so this code will `log` an invocation similar to
  /// `Invocation.method(#add, [42])` and then throw.
  ///
  /// If a value is returned from `noSuchMethod`,
  /// it becomes the result of the original invocation.
  /// If the value is not of a type that can be returned by the original
  /// invocation, a type error occurs at the invocation.
  ///
  /// The default behavior is to throw a [NoSuchMethodError].
  @pragma("vm:entry-point")
  external dynamic noSuchMethod(Invocation invocation);

  /// A representation of the runtime type of the object.
  external Type get runtimeType;
}
