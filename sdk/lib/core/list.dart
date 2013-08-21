// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * An indexable collection of objects with a length.
 *
 * Subclasses of this class implement different kinds of lists.
 * The most common kinds of lists are:
 *
 * * Fixed-length list.
 *   An error occurs when attempting to use operations
 *   that can change the length of the list.
 *
 * * Growable list. Full implementation of the API defined in this class.
 *
 * The following code illustrates that some List implementations support
 * only a subset of the API.
 *
 *     var fixedLengthList = new List(5);
 *     fixedLengthList.length = 0;  // Error.
 *     fixedLengthList.add(499);    // Error.
 *     fixedLengthList[0] = 87;
 *
 *     var growableList = [1, 2];
 *     growableList.length = 0;
 *     growableList.add(499);
 *     growableList[0] = 87;
 *
 * Lists are [Iterable].
 * Iteration occurs over values in index order.
 * Changing the values does not affect iteration,
 * but changing the valid indices&mdash;that is,
 * changing the list's length&mdash;between
 * iteration steps
 * causes a [ConcurrentModificationError].
 * This means that only growable lists can throw ConcurrentModificationError.
 * If the length changes temporarily
 * and is restored before continuing the iteration,
 * the iterator does not detect it.
 */
abstract class List<E> implements Iterable<E> {
  /**
   * Creates a list of the given _length_.
   *
   * The created list is fixed-length if _length_ is provided.
   * The list has length 0 and is growable if _length_ is omitted.
   *
   * An error occurs if _length_ is negative.
   */
  external factory List([int length]);

  /**
   * Creates a fixed-length list of the given _length_
   * and initializes the value at each position with [fill].
   */
  external factory List.filled(int length, E fill);

  /**
   * Creates a list and initializes it using the contents of [other].
   *
   * The [Iterator] of [other] provides the order of the objects.
   *
   * This constructor returns a growable list if [growable] is true;
   * otherwise, it returns a fixed-length list.
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
   * Generates a list of values.
   *
   * Creates a list with _length_ positions
   * and fills it with values created by calling [generator]
   * for each index in the range `0` .. `length - 1`
   * in increasing order.
   *
   * The created list is fixed-length unless [growable] is true.
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
   * Returns the object at the given [index] in the list
   * or throws a [RangeError] if [index] is out of bounds.
   */
  E operator [](int index);

  /**
   * Sets the value at the given [index] in the list to [value]
   * or throws a [RangeError] if [index] is out of bounds.
   */
  void operator []=(int index, E value);

  /**
   * Returns the number of objects in this list.
   *
   * The valid indices for a list are `0` through `length - 1`.
   */
  int get length;

  /**
   * Changes the length of this list.
   *
   * If [newLength] is greater than
   * the current [length], entries are initialized to [:null:].
   *
   * Throws an [UnsupportedError] if the list is fixed-length.
   */
  void set length(int newLength);

  /**
   * Adds [value] to the end of this list,
   * extending the length by one.
   *
   * Throws an [UnsupportedError] if the list is fixed-length.
   */
  void add(E value);

  /**
   * Appends all objects of [iterable] to the end of this list.
   *
   * Extends the length of the list by the number of objects in [iterable].
   * Throws an [UnsupportedError] if this list is fixed-length.
   */
  void addAll(Iterable<E> iterable);

  /**
   * Returns an [Iterable] of the objects in this list in reverse order.
   */
  Iterable<E> get reversed;

  /**
   * Sorts this list according to the order specified by the [compare] function.
   *
   * The [compare] function must act as a [Comparator].
   *
   * The default List implementations use [Comparable.compare] if
   * [compare] is omitted.
   */
  void sort([int compare(E a, E b)]);

  /**
   * Returns the first index of [element] in this list.
   *
   * Searches the list from index [start] to the length of the list.
   * The first time an object [:o:] is encountered so that [:o == element:],
   * the index of [:o:] is returned.
   * Returns -1 if [element] is not found.
   */
  int indexOf(E element, [int start = 0]);

  /**
   * Returns the last index of [element] in this list.
   *
   * Searches the list backwards from index [start] to 0.
   *
   * The first time an object [:o:] is encountered so that [:o == element:],
   * the index of [:o:] is returned.
   *
   * If [start] is not provided, it defaults to [:this.length - 1:].
   *
   * Returns -1 if [element] is not found.
   */
  int lastIndexOf(E element, [int start]);

  /**
   * Removes all objects from this list;
   * the length of the list becomes zero.
   *
   * Throws an [UnsupportedError], and retains all objects, if this 
   * is a fixed-length list.
   */
  void clear();

  /**
   * Inserts the object at position [index] in this list.
   *
   * This increases the length of the list by one and shifts all objects
   * at or after the index towards the end of the list.
   *
   * An error occurs if the [index] is less than 0 or greater than length.
   * An [UnsupportedError] occurs if the list is fixed-length.
   */
  void insert(int index, E element);

  /**
   * Inserts all objects of [iterable] at position [index] in this list.
   *
   * This increases the length of the list by the length of [iterable] and
   * shifts all later objects towards the end of the list.
   *
   * An error occurs if the [index] is less than 0 or greater than length.
   * An [UnsupportedError] occurs if the list is fixed-length.
   */
  void insertAll(int index, Iterable<E> iterable);

  /**
   * Overwrites objects of `this` with the objects of [iterable], starting
   * at position [index] in this list.
   *
   * This operation does not increase the length of `this`.
   *
   * An error occurs if the [index] is less than 0 or greater than length.
   * An error occurs if the [iterable] is longer than [length] - [index].
   */
  void setAll(int index, Iterable<E> iterable);

  /**
   * Removes [value] from this list.
   *
   * Returns true if [value] was in the list.
   * Returns false otherwise.
   * The method has no effect if [value] was not in the list.
   *
   * An [UnsupportedError] occurs if the list is fixed-length.
   */
  bool remove(Object value);

  /**
   * Removes the object at position [index] from this list.
   *
   * This method reduces the length of `this` by one and moves all later objects
   * down by one position.
   *
   * Returns the removed object.
   *
   * * Throws an [ArgumentError] if [index] is not an [int].
   * * Throws a [RangeError] if the [index] is out of range for this list.
   * * Throws an [UnsupportedError], and doesn't remove the object,
   * if this is a fixed-length list.
   */
  E removeAt(int index);

  /**
   * Pops and returns the last object in this list.
   *
   * Throws an [UnsupportedError] if this is a fixed-length list.
   */
  E removeLast();

  /**
   * Removes all objects from this list that satisfy [test].
   *
   * An object [:o:] satisfies [test] if [:test(o):] is true.
   *
   * Throws an [UnsupportedError] if this is a fixed-length list.
   */
  void removeWhere(bool test(E element));

  /**
   * Removes all objects from this list that fail to satisfy [test].
   *
   * An object [:o:] satisfies [test] if [:test(o):] is true.
   *
   * Throws an [UnsupportedError] if this is a fixed-length list.
   */
  void retainWhere(bool test(E element));

  /**
   * Returns a new list containing the objects
   * from [start] inclusive to [end] exclusive.
   *
   * If [end] is omitted, the [length] of `this` is used.
   *
   * An error occurs if [start] is outside the range `0` .. `length` or if
   * [end] is outside the range `start` .. `length`.
   */
  List<E> sublist(int start, [int end]);

  /**
   * Returns an [Iterable] that iterates over the objects in the range
   * [start] inclusive to [end] exclusive.
   *
   * An error occurs if [end] is before [start].
   *
   * An error occurs if the [start] and [end] are not valid ranges at the time
   * of the call to this method. The returned [Iterable] behaves like
   * `skip(start).take(end - start)`. That is, it does not throw exceptions
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
   * Copies the objects of [iterable], skipping [skipCount] objects first,
   * into the range [start] inclusive to [end] exclusive of `this`.
   *
   * If [start] equals [end] and [start]..[end] represents a legal range, this
   * method has no effect.
   *
   * An error occurs if [start]..[end] is not a valid range for `this`.
   * An error occurs if the [iterable] does not have enough objects after
   * skipping [skipCount] objects.
   *
   * Example:
   *
   *     var list = [1, 2, 3, 4];
   *     var list2 = [5, 6, 7, 8, 9];
   *     list.setRange(1, 3, list2, 3);
   *     print(list);  // => [1, 8, 9, 4]
   */
  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]);

  /**
   * Removes the objects in the range [start] inclusive to [end] exclusive.
   *
   * An error occurs if [start]..[end] is not a valid range for `this`.
   * Throws an [UnsupportedError] if this is a fixed-length list.
   */
  void removeRange(int start, int end);

  /**
   * Sets the objects in the range [start] inclusive to [end] exclusive
   * to the given [fillValue].
   *
   * An error occurs if [start]..[end] is not a valid range for `this`.
   */
  void fillRange(int start, int end, [E fillValue]);

  /**
   * Removes the objects in the range [start] inclusive to [end] exclusive
   * and replaces them with the contents of the [iterable].
   *
   * An error occurs if [start]..[end] is not a valid range for `this`.
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
   * The map uses the indices of this list as keys and the corresponding objects
   * as values. The `Map.keys` [Iterable] iterates the indices of this list
   * in numerical order.
   */
  Map<int, E> asMap();
}
