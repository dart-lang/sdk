// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * A [List] is an indexable collection with a length.
 *
 * A `List` implementation can choose not to support all methods
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
abstract class List<E> implements Iterable<E> {
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
   * Returns the number of elements in the list.
   *
   * The valid indices for a list are 0 through `length - 1`.
   */
  int get length;

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
   * Inserts the element at position [index] in the list.
   *
   * This increases the length of the list by one and shifts all later elements
   * towards the end of the list.
   *
   * It is an error if the [index] does not point inside the list or at the
   * position after the last element.
   */
  void insert(int index, E element);

  /**
   * Inserts all elements of [iterable] at position [index] in the list.
   *
   * This increases the length of the list by the length of [iterable] and
   * shifts all later elements towards the end of the list.
   *
   * It is an error if the [index] does not point inside the list or at the
   * position after the last element.
   */
  void insertAll(int index, Iterable<E> iterable);

  /**
   * Overwrites elements of `this` with the elemenst of [iterable] starting
   * at position [index] in the list.
   *
   * This operation does not increase the length of the list.
   *
   * It is an error if the [index] does not point inside the list or at the
   * position after the last element.
   *
   * It is an error if the [iterable] is longer than [length] - [index].
   */
  void setAll(int index, Iterable<E> iterable);

  /**
   * Removes [value] from the list. Returns true if [value] was
   * in the list. Returns false otherwise. The method has no effect
   * if [value] value was not in the list.
   */
  bool remove(Object value);

  /**
   * Removes the element at position [index] from the list.
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
   * Removes all elements of this list that satisfy [test].
   *
   * An elements [:e:] satisfies [test] if [:test(e):] is true.
   */
  void removeWhere(bool test(E element));

  /**
   * Removes all elements of this list that fail to satisfy [test].
   *
   * An elements [:e:] satisfies [test] if [:test(e):] is true.
   */
  void retainWhere(bool test(E element));

  /**
   * Returns a new list containing the elements from [start] to [end].
   *
   * If [end] is omitted, the [length] of the list is used.
   *
   * It is an error if [start] or [end] are not list indices for this list,
   * or if [end] is before [start].
   */
  List<E> sublist(int start, [int end]);

  /**
   * Returns an [Iterable] that iterators over the elements in the range
   * [start] to [end] (exclusive). The result of this function is backed by
   * `this`.
   *
   * It is an error if [end] is before [start].
   *
   * It is an error if the [start] and [end] are not valid ranges at the time
   * of the call to this method. The returned [Iterable] behaves similar to
   * `skip(start).take(end - start)`. That is, it will not throw exceptions
   * if `this` changes size.
   *
   * Example:
   *
   *     var list = [1, 2, 3, 4, 5];
   *     var range = list.getRange(1, 4);
   *     print(range.join(', '));  // => 2, 3, 4
   *     list.length = 3;
   *     print(range.join(', '));  // => 2, 3
   */
  Iterable<E> getRange(int start, int end);

  /**
   * Copies the elements of [iterable], skipping the [skipCount] first elements
   * into the range [start] - [end] (excluding) of `this`.
   *
   * If [start] equals [end] and represent a legal range, this method has
   * no effect.
   *
   * It is an error if [start]..[end] is not a valid range pointing into the
   * `this`.
   *
   * It is an error if the [iterable] does not have enough elements after
   * skipping [skipCount] elements.
   */
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]);

  /**
   * Removes the elements in the range [start]..[end] (excluding).
   *
   * It is an error if [start]..[end] is not a valid range pointing into the
   * `this`.
   */
  void removeRange(int start, int end);

  /**
   * Sets the elements in the range [start]..[end] (excluding) to the given
   * [fillValue].
   *
   * It is an error if [start]..[end] is not a valid range pointing into the
   * `this`.
   */
  void fillRange(int start, int end, [E fillValue]);

  /**
   * Removes the elements in the range [start]..[end] (excluding) and replaces
   * them with the contents of the [iterable].
   *
   * It is an error if [start]..[end] is not a valid range pointing into the
   * `this`.
   *
   * Example:
   *
   *     var list = [1, 2, 3, 4, 5];
   *     list.replaceRange(1, 3, [6, 7, 8, 9]);
   *     print(list);  // [1, 6, 7, 8, 9, 4, 5]
   */
  void replaceRange(int start, int end, Iterable<E> iterable);

  /**
   * Returns an unmodifiable [Map] view of `this`.
   *
   * It has the indices of this list as keys, and the corresponding elements
   * as values.
   */
  Map<int, E> asMap();
}
