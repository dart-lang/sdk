// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * A [List] is an indexable collection with a length.
 *
 * A `List` implementation can be choose not to support all methods
 * of the `List` interface.
 *
 * The most common list types are:
 * * Fixed length list. It is an error to use operations that can change
 *   the list's length.
 * * Growable list. Full implementation of the interface.
 * * Unmodifiable list. It is an error to use operations that can change
 *   the list's length, or that can change the values of the list.
 *   If an unmodifable list is backed by another modifiable data structure,
 *   the values read from it may still change over time.
 *
 * Example:
 *
 *    var fixedLengthList = new List(5);
 *    fixedLengthList.length = 0;  // throws.
 *    fixedLengthList.add(499);  // throws
 *    fixedLengthList[0] = 87;
 *    var growableList = [1, 2];
 *    growableList.length = 0;
 *    growableList.add(499);
 *    growableList[0] = 87;
 *    var unmodifiableList = const [1, 2];
 *    unmodifiableList.length = 0;  // throws.
 *    unmodifiableList.add(499);  // throws
 *    unmodifiableList[0] = 87;  // throws.
 */
abstract class List<E> implements Collection<E> {
  /**
   * Creates a list of the given [length].
   *
   * The list is a fixed-length list if [length] is provided, and an empty
   * growable list if [length] is omitted.
   */
  external factory List([int length]);

  /**
   * Creates a fixed-length list of the given [length] where each entry
   * contains [fill].
   */
  external factory List.filled(int length, E fill);

  /**
   * *Deprecated*: Use `new List(count)` instead.
   */
  factory List.fixedLength(int count, { E fill }) {
    List<E> result = new List(count);
    if (fill != null) {
      for (int i = 0; i < count; i++) result[i] = fill;
    }
    return result;
  }

  /**
   * Creates an list with the elements of [other]. The order in
   * the list will be the order provided by the iterator of [other].
   *
   * The returned list is growable if [growable] is true, otherwise it's
   * a fixed length list.
   */
  factory List.from(Iterable other, { bool growable: true }) {
    List<E> list = new List<E>();
    for (E e in other) {
      list.add(e);
    }
    if (growable) return list;
    int length = list.length;
    List<E> fixedList = new List<E>(length);
    for (int i = 0; i < length; i++) {
      fixedList[i] = list[i];
    }
    return fixedList;
  }

  /**
   * Generate a `List` of elements.
   *
   * Generates a list of values, where the values are created by
   * calling the [generator] function for each index in the range
   * 0 .. [length] - 1.
   *
   * The created length's length is fixed unless [growable] is true.
   */
  factory List.generate(int length, E generator(int index),
                       { bool growable: true }) {
    List<E> result;
    if (growable) {
      result = <E>[]..length = length;
    } else {
      result = new List<E>(length);
    }
    for (int i = 0; i < length; i++) {
      result[i] = generator(i);
    }
    return result;
  }

  /**
   * Returns the element at the given [index] in the list or throws
   * an [RangeError] if [index] is out of bounds.
   */
  E operator [](int index);

  /**
   * Sets the entry at the given [index] in the list to [value].
   * Throws an [RangeError] if [index] is out of bounds.
   */
  void operator []=(int index, E value);

  /**
   * Changes the length of the list. If [newLength] is greater than
   * the current [length], entries are initialized to [:null:]. Throws
   * an [UnsupportedError] if the list is not extendable.
   */
  void set length(int newLength);

  /**
   * Adds [value] at the end of the list, extending the length by
   * one. Throws an [UnsupportedError] if the list is not
   * extendable.
   */
  void add(E value);

  /**
   * Adds [value] at the end of the list, extending the length by
   * one. Throws an [UnsupportedError] if the list is not
   * extendable.
   *
   * *Deprecated*: Use [add] instead.
   */
  @deprecated
  void addLast(E value);

  /**
   * Appends all elements of the [iterable] to the end of this list.
   * Extends the length of the list by the number of elements in [iterable].
   * Throws an [UnsupportedError] if this list is not extensible.
   */
  void addAll(Iterable<E> iterable);

  /**
   * Returns an [Iterable] of the elements of this [List] in reverse order.
   */
  Iterable<E> get reversed;

  /**
   * Sorts the list according to the order specified by the [compare] function.
   *
   * The [compare] function must act as a [Comparator].
   * The default [List] implementations use [Comparable.compare] if
   * [compare] is omitted.
   */
  void sort([int compare(E a, E b)]);

  /**
   * Returns the first index of [element] in the list.
   *
   * Searches the list from index [start] to the length of the list.
   * The first time an element [:e:] is encountered so that [:e == element:],
   * the index of [:e:] is returned.
   * Returns -1 if [element] is not found.
   */
  int indexOf(E element, [int start = 0]);

  /**
   * Returns the last index of [element] in the list.
   *
   * Searches the list backwards from index [start] (inclusive) to 0.
   * The first time an element [:e:] is encountered so that [:e == element:],
   * the index of [:e:] is returned.
   * If start is not provided, it defaults to [:this.length - 1:] .
   * Returns -1 if [element] is not found.
   */
  int lastIndexOf(E element, [int start]);

  /**
   * Removes all elements in the list.
   *
   * The length of the list becomes zero.
   * Throws an [UnsupportedError], and retains all elements, if the
   * length of the list cannot be changed.
   */
  void clear();

  /**
   * Removes the element at position[index] from the list.
   *
   * This reduces the length of the list by one and moves all later elements
   * down by one position.
   * Returns the removed element.
   * Throws an [ArgumentError] if [index] is not an [int].
   * Throws an [RangeError] if the [index] does not point inside
   * the list.
   * Throws an [UnsupportedError], and doesn't remove the element,
   * if the length of the list cannot be changed.
   */
  E removeAt(int index);

  /**
   * Pops and returns the last element of the list.
   * Throws a [UnsupportedError] if the length of the
   * list cannot be changed.
   */
  E removeLast();

  /**
   * Returns a new list containing [length] elements from the list,
   * starting at  [start].
   * Returns an empty list if [length] is 0.
   * Throws an [ArgumentError] if [length] is negative.
   * Throws an [RangeError] if [start] or
   * [:start + length - 1:] are out of range.
   */
  List<E> getRange(int start, int length);

  /**
   * Copies [length] elements of [from], starting
   * at [startFrom], into the list, starting at [start].
   * If [length] is 0, this method does not do anything.
   * Throws an [ArgumentError] if [length] is negative.
   * Throws an [RangeError] if [start] or
   * [:start + length - 1:] are out of range for [:this:], or if
   * [startFrom] or [:startFrom + length - 1:] are out of range for [from].
   */
  void setRange(int start, int length, List<E> from, [int startFrom]);

  /**
   * Removes [length] elements from the list, beginning at [start].
   * Throws an [UnsupportedError] if the list is
   * not extendable.
   * If [length] is 0, this method does not do anything.
   * Throws an [ArgumentError] if [length] is negative.
   * Throws an [RangeError] if [start] or
   * [:start + length: - 1] are out of range.
   */
  void removeRange(int start, int length);

  /**
   * Inserts a new range into the list, starting from [start] to
   * [:start + length - 1:]. The entries are filled with [fill].
   * Throws an [UnsupportedError] if the list is
   * not extendable.
   * If [length] is 0, this method does not do anything.
   * If [start] is the length of the list, this method inserts the
   * range at the end of the list.
   * Throws an [ArgumentError] if [length] is negative.
   * Throws an [RangeError] if [start] is negative or if
   * [start] is greater than the length of the list.
   */
  void insertRange(int start, int length, [E fill]);

  /**
   * Returns an unmodifiable [Map] view of `this`.
   *
   * It has the indices of this list as keys, and the corresponding elements
   * as values.
   */
  Map<int, E> asMap();
}
