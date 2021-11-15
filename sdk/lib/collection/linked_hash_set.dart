// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/// A [LinkedHashSet] is a hash-table based [Set] implementation.
///
/// Default implementation of [Set] is [LinkedHashSet].
///
/// The `LinkedHashSet` also keep track of the order that elements were inserted
/// in, and iteration happens in first-to-last insertion order.
///
/// The elements of a `LinkedHashSet` must have consistent [Object.==]
/// and [Object.hashCode] implementations. This means that the `==` operator
/// must define a stable equivalence relation on the elements (reflexive,
/// symmetric, transitive, and consistent over time), and that `hashCode`
/// must be the same for objects that are considered equal by `==`.
///
/// Iteration of elements is done in element insertion order.
/// An element that was added after another will occur later in the iteration.
/// Adding an element that is already in the set
/// does not change its position in the iteration order,
/// but removing an element and adding it again,
/// will make it the last element of an iteration.
///
/// Most simple operations on `HashSet` are done in (potentially amortized)
/// constant time: [add], [contains], [remove], and [length], provided the hash
/// codes of objects are well distributed.
///
/// **Notice:**
/// It is generally not allowed to modify the set (add or remove elements) while
/// an operation on the set is being performed, for example during a call to
/// [forEach] or [containsAll]. Nor is it allowed to modify the set while
/// iterating either the set itself or any [Iterable] that is backed by the set,
/// such as the ones returned by methods like [where] and [map].
///
/// It is generally not allowed to modify the equality of elements (and thus not
/// their hashcode) while they are in the set. Some specialized subtypes may be
/// more permissive, in which case they should document this behavior.
///
///
/// Example:
/// ```dart
/// final planets = LinkedHashSet();
/// planets.addAll({'Venus', 'Mars', 'Earth', 'Jupiter'});
/// planets.isEmpty; // false
/// planets.length; // 4
/// print(planets); // {Venus, Mars, Earth, Jupiter}
///
/// // To check is there a value item on map, call contains
/// final marsExists = planets.contains('Mars'); // true
///
/// // To get element value using index, call elementAt
/// final elementAt = planets.elementAt(1);
/// print(elementAt); // Mars
///
/// // The forEach iterates through all entries of a set.
/// planets.forEach((element) {
///   print(element);
///   // Venus
///   // Mars
///   // Earth
///   // Jupiter
/// });
///
/// // To convert set to list, call toList
/// final toList = planets.toList();
/// print(toList); // [Venus, Mars, Earth, Jupiter]
///
/// // To make a copy of set, call toSet
/// final copySet = planets.toSet();
/// print(copySet); // {Venus, Mars, Earth, Jupiter}
///
/// // To add item to set, call add
/// final uranusAdded = planets.add('Uranus');
/// print(planets); // {Venus, Mars, Earth, Jupiter, Uranus}
///
/// // To remove specific value, call remove
/// final removedValue = planets.remove('Mars'); // Mars
/// print(planets); // {Venus, Earth, Jupiter, Uranus}
///
/// // To remove value(s) with a statement, call removeWhere
/// planets.removeWhere((element) => element.contains('Earth'));
/// print(planets); // {Venus, Jupiter, Uranus}
///
/// // To remove other values than those which match statement
/// planets.retainWhere((element) => element.contains('C'));
/// print(planets); // {Jupiter}
///
/// // To clean up data, call clear
/// planets.clear();
/// print(planets); // {}
/// ```
/// **See also:**
/// * [Set] is a base-class for collection of objects.
/// * [HashSet] the order of the objects in the iterations is not guaranteed.
/// * [SplayTreeSet] the order of the objects can be relative to each other.
abstract class LinkedHashSet<E> implements Set<E> {
  /// Create an insertion-ordered hash set using the provided
  /// [equals] and [hashCode].
  ///
  /// The provided [equals] must define a stable equivalence relation, and
  /// [hashCode] must be consistent with [equals].
  ///
  /// If you supply one of [equals] and [hashCode],
  /// you should generally also to supply the other.
  ///
  /// Some [equals] or [hashCode] functions might not work for all objects.
  /// If [isValidKey] is supplied, it's used to check a potential element
  /// which is not necessarily an instance of [E], like the argument to
  /// [contains] which is typed as `Object?`.
  /// If [isValidKey] returns `false`, for an object, the [equals] and
  /// [hashCode] functions are not called, and no key equal to that object
  /// is assumed to be in the map.
  /// The [isValidKey] function defaults to just testing if the object is an
  /// instance of [E], which means that:
  /// ```dart template:expression
  /// LinkedHashSet<int>(equals: (int e1, int e2) => (e1 - e2) % 5 == 0,
  ///                    hashCode: (int e) => e % 5);
  /// ```
  /// does not need an `isValidKey` argument, because it defaults to only
  /// accepting `int` values which are accepted by both `equals` and `hashCode`.
  ///
  /// If neither `equals`, `hashCode`, nor `isValidKey` is provided,
  /// the default `isValidKey` instead accepts all values.
  /// The default equality and hashcode operations are assumed to work on all
  /// objects.
  ///
  /// Likewise, if `equals` is [identical], `hashCode` is [identityHashCode]
  /// and `isValidKey` is omitted, the resulting set is identity based,
  /// and the `isValidKey` defaults to accepting all keys.
  /// Such a map can be created directly using [LinkedHashSet.identity].
  external factory LinkedHashSet(
      {bool Function(E, E)? equals,
      int Function(E)? hashCode,
      bool Function(dynamic)? isValidKey});

  /// Creates an insertion-ordered identity-based set.
  ///
  /// Effectively a shorthand for:
  /// ```dart
  /// LinkedHashSet<E>(equals: identical, hashCode: identityHashCode)
  /// ```
  external factory LinkedHashSet.identity();

  /// Create a linked hash set containing all [elements].
  ///
  /// Creates a linked hash set as by `LinkedHashSet<E>()` and adds each
  /// element of `elements` to this set in the order they are iterated.
  ///
  /// All the [elements] should be instances of [E].
  /// The `elements` iterable itself may have any element type,
  /// so this constructor can be used to down-cast a `Set`, for example as:
  /// ```dart
  /// Set<SuperType> superSet = ...;
  /// Iterable<SuperType> tmp = superSet.where((e) => e is SubType);
  /// Set<SubType> subSet = LinkedHashSet<SubType>.from(tmp);
  /// ```
  /// Example:
  /// ```dart
  /// final baseSet = {'A', 'B', 'C'};
  /// final hashSetFrom = LinkedHashSet.from(baseSet);
  /// print(hashSetFrom); // {A, B, C}
  /// ```
  factory LinkedHashSet.from(Iterable<dynamic> elements) {
    LinkedHashSet<E> result = LinkedHashSet<E>();
    for (final element in elements) {
      result.add(element as E);
    }
    return result;
  }

  /// Create a linked hash set from [elements].
  ///
  /// Creates a linked hash set as by `LinkedHashSet<E>()` and adds each
  /// element of `elements` to this set in the order they are iterated.
  /// Example:
  /// ```dart
  /// final baseSet = {'A', 'B', 'C'};
  /// final setOf = LinkedHashSet.of(baseSet);
  /// print(setOf); // {A, B, C}
  /// ```
  factory LinkedHashSet.of(Iterable<E> elements) =>
      LinkedHashSet<E>()..addAll(elements);

  /// Executes a function on each element of the set.
  ///
  /// The elements are iterated in insertion order.
  void forEach(void action(E element));

  /// Provides an iterator that iterates over the elements in insertion order.
  Iterator<E> get iterator;
}
