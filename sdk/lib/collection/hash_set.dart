// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

/// An unordered hash-table based [Set] implementation.
///
/// The elements of a `HashSet` must have consistent equality
/// and hashCode implementations. This means that the equals operation
/// must define a stable equivalence relation on the elements (reflexive,
/// symmetric, transitive, and consistent over time), and that the hashCode
/// must consistent with equality, so that the same for objects that are
/// considered equal.
///
/// Most simple operations on `HashSet` are done in (potentially amortized)
/// constant time: [add], [contains], [remove], and [length], provided the hash
/// codes of objects are well distributed.
///
/// **The iteration order of the set is not specified and depends on
/// the hashcodes of the provided elements.** However, the order is stable:
/// multiple iterations over the same set produce the same order, as long as
/// the set is not modified.
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
/// Example:
///
/// ```dart
/// final hashSet = HashSet();
/// hashSet.addAll({'A', 'B', 'C', 'D'});
/// hashSet.isEmpty; // false
/// hashSet.length; // 4
/// print(hashSet); // {A, D, C, B}
///
/// // To check is there a value item on map, call contains
/// final bExists = hashSet.contains('B'); // true
///
/// // To get element value using index, call elementAt
/// final elementAt = hashSet.elementAt(1);
/// print(elementAt); // D
///
/// // The forEach iterates through all entries of a set
/// hashSet.forEach((element) {
///   print(element);
///   // A
///   // D
///   // C
///   // B
/// });
///
/// // To convert set to list, call toList
/// final toList = hashSet.toList();
/// print(toList); // [A, D, C, B]
///
/// // To make a copy of set, call toSet
/// final copyOfOriginal = hashSet.toSet();
/// print(copyOfOriginal); // {A, C, D, B}
///
/// // To add item to set, call [add]
/// final addedValue = hashSet.add('E'); // true
/// print(hashSet); // {A, D, C, E, B}
///
/// // To remove specific value, call remove
/// final removedValue = hashSet.remove('A'); // true
/// print(hashSet); // {D, C, E, B}
///
/// // To remove value(s) with a statement, call the removeWhere
/// hashSet.removeWhere((element) => element.contains('B'));
/// print(hashSet); // {D, C, E}
///
/// // To remove other values than those which match statement
/// hashSet.retainWhere((element) => element.contains('C'));
/// print(hashSet); // {C}
///
/// // To clean up data, call the clear
/// hashSet.clear();
/// print(hashSet); // {}
/// ```
/// **See also:**
/// * [Set] is a base-class for collection of objects.
/// * [LinkedHashSet] objects stored based on insertion order.
/// * [SplayTreeSet] the order of the objects can be relative to each other.
abstract class HashSet<E> implements Set<E> {
  /// Create a hash set using the provided [equals] as equality.
  ///
  /// The provided [equals] must define a stable equivalence relation, and
  /// [hashCode] must be consistent with [equals]. If the [equals] or [hashCode]
  /// methods won't work on all objects, but only on some instances of E, the
  /// [isValidKey] predicate can be used to restrict the keys that the functions
  /// are applied to.
  /// Any key for which [isValidKey] returns false is automatically assumed
  /// to not be in the set when asking `contains`.
  ///
  /// If [equals] or [hashCode] are omitted, the set uses
  /// the elements' intrinsic [Object.==] and [Object.hashCode].
  ///
  /// If you supply one of [equals] and [hashCode],
  /// you should generally also to supply the other.
  ///
  /// If the supplied `equals` or `hashCode` functions won't work on all [E]
  /// objects, and the map will be used in a setting where a non-`E` object
  /// is passed to, e.g., `contains`, then the [isValidKey] function should
  /// also be supplied.
  ///
  /// If [isValidKey] is omitted, it defaults to testing if the object is an
  /// [E] instance. That means that:
  /// ```dart template:expression
  /// HashSet<int>(equals: (int e1, int e2) => (e1 - e2) % 5 == 0,
  ///              hashCode: (int e) => e % 5);
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
  /// Such a map can be created directly using [HashSet.identity].
  external factory HashSet(
      {bool Function(E, E)? equals,
      int Function(E)? hashCode,
      bool Function(dynamic)? isValidKey});

  /// Creates an unordered identity-based set.
  ///
  /// Effectively a shorthand for:
  /// ```dart
  /// HashSet<E>(equals: identical, hashCode: identityHashCode)
  /// ```
  external factory HashSet.identity();

  /// Create a hash set containing all [elements].
  ///
  /// Creates a hash set as by `HashSet<E>()` and adds all given [elements]
  /// to the set. The elements are added in order. If [elements] contains
  /// two entries that are equal, but not identical, then the first one is
  /// the one in the resulting set.
  ///
  /// All the [elements] should be instances of [E].
  /// The `elements` iterable itself may have any element type, so this
  /// constructor can be used to down-cast a `Set`, for example as:
  /// ```dart
  /// Set<SuperType> superSet = ...;
  /// Set<SubType> subSet =
  ///     HashSet<SubType>.from(superSet.whereType<SubType>());
  /// ```
  /// Example:
  /// ```dart
  /// final baseSet = {'A', 'B', 'C'};
  /// final hashSetFrom = HashSet.from(baseSet);
  /// print(hashSetFrom); // {A, C, B}
  /// ```
  factory HashSet.from(Iterable<dynamic> elements) {
    HashSet<E> result = HashSet<E>();
    for (final e in elements) {
      result.add(e as E);
    }
    return result;
  }

  /// Create a hash set containing all [elements].
  ///
  /// Creates a hash set as by `HashSet<E>()` and adds all given [elements]
  /// to the set. The elements are added in order. If [elements] contains
  /// two entries that are equal, but not identical, then the first one is
  /// the one in the resulting set.
  /// Example:
  /// ```dart
  /// final baseSet = {'A', 'B', 'C'};
  /// final hashSetOf = HashSet.of(baseSet);
  /// print(hashSetOf); // {A, C, B}
  /// ```
  factory HashSet.of(Iterable<E> elements) => HashSet<E>()..addAll(elements);

  /// Provides an iterator that iterates over the elements of this set.
  ///
  /// The order of iteration is unspecified,
  /// but consistent between changes to the set.
  Iterator<E> get iterator;
}
