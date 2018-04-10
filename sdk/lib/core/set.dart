// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * A collection of objects in which each object can occur only once.
 *
 * That is, for each object of the element type, the object is either considered
 * to be in the set, or to _not_ be in the set.
 *
 * Set implementations may consider some elements indistinguishable. These
 * elements are treated as being the same for any operation on the set.
 *
 * The default [Set] implementation, [LinkedHashSet], considers objects
 * indistinguishable if they are equal with regard to
 * operator [Object.==].
 *
 * Iterating over elements of a set may be either unordered
 * or ordered in some way. Examples:
 *
 * * A [HashSet] is unordered, which means that its iteration order is
 *   unspecified,
 * * [LinkedHashSet] iterates in the insertion order of its elements, and
 * * a sorted set like [SplayTreeSet] iterates the elements in sorted order.
 *
 * It is generally not allowed to modify the set (add or remove elements) while
 * an operation on the set is being performed, for example during a call to
 * [forEach] or [containsAll]. Nor is it allowed to modify the set while
 * iterating either the set itself or any [Iterable] that is backed by the set,
 * such as the ones returned by methods like [where] and [map].
 *
 * It is generally not allowed to modify the equality of elements (and thus not
 * their hashcode) while they are in the set. Some specialized subtypes may be
 * more permissive, in which case they should document this behavior.
 */
abstract class Set<E> extends EfficientLengthIterable<E> {
  /**
   * Creates an empty [Set].
   *
   * The created [Set] is a plain [LinkedHashSet].
   * As such, it considers elements that are equal (using [operator ==]) to be
   * indistinguishable, and requires them to have a compatible
   * [Object.hashCode] implementation.
   *
   * The set is equivalent to one created by `new LinkedHashSet<E>()`.
   */
  factory Set() = LinkedHashSet<E>;

  /**
   * Creates an empty identity [Set].
   *
   * The created [Set] is a [LinkedHashSet] that uses identity as equality
   * relation.
   *
   * The set is equivalent to one created by `new LinkedHashSet<E>.identity()`.
   */
  factory Set.identity() = LinkedHashSet<E>.identity;

  /**
   * Creates a [Set] that contains all [elements].
   *
   * All the [elements] should be instances of [E].
   * The `elements` iterable itself can have any type,
   * so this constructor can be used to down-cast a `Set`, for example as:
   *
   *     Set<SuperType> superSet = ...;
   *     Set<SubType> subSet =
   *         new Set<SubType>.from(superSet.where((e) => e is SubType));
   *
   * The created [Set] is a [LinkedHashSet]. As such, it considers elements that
   * are equal (using [operator ==]) to be indistinguishable, and requires them to
   * have a compatible [Object.hashCode] implementation.
   *
   * The set is equivalent to one created by
   * `new LinkedHashSet<E>.from(elements)`.
   */
  factory Set.from(Iterable elements) = LinkedHashSet<E>.from;

  /**
   * Creates a [Set] from [elements].
   *
   * The created [Set] is a [LinkedHashSet]. As such, it considers elements that
   * are equal (using [operator ==]) to be indistinguishable, and requires them to
   * have a compatible [Object.hashCode] implementation.
   *
   * The set is equivalent to one created by
   * `new LinkedHashSet<E>.of(elements)`.
   */
  factory Set.of(Iterable<E> elements) = LinkedHashSet<E>.of;

  /**
   * Adapts [source] to be a `Set<T>`.
   *
   * If [newSet] is provided, it is used to create the new sets returned
   * by [toSet], [union], and is also used for [intersection] and [difference].
   * If [newSet] is omitted, it defaults to creating a new set using the
   * default [Set] constructor, and [intersection] and [difference]
   * returns an adapted version of calling the same method on the source.
   *
   * Any time the set would produce an element that is not a [T],
   * the element access will throw.
   *
   * Any time a [T] value is attempted added into the adapted set,
   * the store will throw unless the value is also an instance of [S].
   *
   * If all accessed elements of [source] are actually instances of [T],
   * and if all elements added to the returned set are actually instance
   * of [S],
   * then the returned set can be used as a `Set<T>`.
   */
  static Set<T> castFrom<S, T>(Set<S> source, {Set<R> Function<R>() newSet}) =>
      new CastSet<S, T>(source, newSet);

  /**
   * Provides a view of this set as a set of [R] instances, if necessary.
   *
   * If this set is already a `Set<R>`, it is returned unchanged.
   *
   * If this set contains only instances of [R], all read operations
   * will work correctly. If any operation tries to access an element
   * that is not an instance of [R], the access will throw instead.
   *
   * Elements added to the set (e.g., by using [add] or [addAll])
   * must be instance of [R] to be valid arguments to the adding function,
   * and they must be instances of [E] as well to be accepted by
   * this set as well.
   */
  Set<R> cast<R>();

  /**
   * Provides a view of this set as a set of [R] instances.
   *
   * If this set contains only instances of [R], all read operations
   * will work correctly. If any operation tries to access an element
   * that is not an instance of [R], the access will throw instead.
   *
   * Elements added to the set (e.g., by using [add] or [addAll])
   * must be instance of [R] to be valid arguments to the adding function,
   * and they must be instances of [E] as well to be accepted by
   * this set as well.
   */
  Set<R> retype<R>();

  /**
   * Provides an iterator that iterates over the elements of this set.
   *
   * The order of iteration is defined by the individual `Set` implementation,
   * but must be consistent between changes to the set.
   */
  Iterator<E> get iterator;

  /**
   * Returns true if [value] is in the set.
   */
  bool contains(Object value);

  /**
   * Adds [value] to the set.
   *
   * Returns `true` if [value] (or an equal value) was not yet in the set.
   * Otherwise returns `false` and the set is not changed.
   *
   * Example:
   *
   *     var set = new Set();
   *     var time1 = new DateTime.fromMillisecondsSinceEpoch(0);
   *     var time2 = new DateTime.fromMillisecondsSinceEpoch(0);
   *     // time1 and time2 are equal, but not identical.
   *     Expect.isTrue(time1 == time2);
   *     Expect.isFalse(identical(time1, time2));
   *     set.add(time1);  // => true.
   *     // A value equal to time2 exists already in the set, and the call to
   *     // add doesn't change the set.
   *     set.add(time2);  // => false.
   *     Expect.isTrue(set.length == 1);
   *     Expect.isTrue(identical(time1, set.first));
   */
  bool add(E value);

  /**
   * Adds all [elements] to this Set.
   *
   * Equivalent to adding each element in [elements] using [add],
   * but some collections may be able to optimize it.
   */
  void addAll(Iterable<E> elements);

  /**
   * Removes [value] from the set. Returns true if [value] was
   * in the set. Returns false otherwise. The method has no effect
   * if [value] value was not in the set.
   */
  bool remove(Object value);

  /**
   * If an object equal to [object] is in the set, return it.
   *
   * Checks if there is an object in the set that is equal to [object].
   * If so, that object is returned, otherwise returns null.
   */
  E lookup(Object object);

  /**
   * Removes each element of [elements] from this set.
   */
  void removeAll(Iterable<Object> elements);

  /**
   * Removes all elements of this set that are not elements in [elements].
   *
   * Checks for each element of [elements] whether there is an element in this
   * set that is equal to it (according to `this.contains`), and if so, the
   * equal element in this set is retained, and elements that are not equal
   * to any element in `elements` are removed.
   */
  void retainAll(Iterable<Object> elements);

  /**
   * Removes all elements of this set that satisfy [test].
   */
  void removeWhere(bool test(E element));

  /**
   * Removes all elements of this set that fail to satisfy [test].
   */
  void retainWhere(bool test(E element));

  /**
   * Returns whether this Set contains all the elements of [other].
   */
  bool containsAll(Iterable<Object> other);

  /**
   * Returns a new set which is the intersection between this set and [other].
   *
   * That is, the returned set contains all the elements of this [Set] that
   * are also elements of [other] according to `other.contains`.
   */
  Set<E> intersection(Set<Object> other);

  /**
   * Returns a new set which contains all the elements of this set and [other].
   *
   * That is, the returned set contains all the elements of this [Set] and
   * all the elements of [other].
   */
  Set<E> union(Set<E> other);

  /**
   * Returns a new set with the elements of this that are not in [other].
   *
   * That is, the returned set contains all the elements of this [Set] that
   * are not elements of [other] according to `other.contains`.
   */
  Set<E> difference(Set<Object> other);

  /**
   * Removes all elements in the set.
   */
  void clear();

  /* Creates a [Set] with the same elements and behavior as this `Set`.
   *
   * The returned set behaves the same as this set
   * with regard to adding and removing elements.
   * It initially contains the same elements.
   * If this set specifies an ordering of the elements,
   * the returned set will have the same order.
   */
  Set<E> toSet();
}
