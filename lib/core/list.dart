// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A [List] is an indexable collection with a length. It can be of
 * fixed size or extendable.
 */
interface List<E> extends Collection<E>, Sequence<E>
                  default _ListImpl<E> {
  /**
   * Creates a list of the given [length].
   *
   * If no [length] argument is supplied an extendable list of
   * length 0 is created.
   *
   * If a [length] argument is supplied, a fixed size list of that
   * length is created.
   */
  List([int length]);

  /**
   * Creates a list with the elements of [other]. The order in
   * the list will be the order provided by the iterator of [other].
   */
  List.from(Iterable<E> other);

  /**
   * Returns the element at the given [index] in the list or throws
   * an [IndexOutOfRangeException] if [index] is out of bounds.
   */
  E operator [](int index);

  /**
   * Sets the entry at the given [index] in the list to [value].
   * Throws an [IndexOutOfRangeException] if [index] is out of bounds.
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
   */
  void addLast(E value);

  /**
   * Appends all elements of the [collection] to the end of this list.
   * Extends the length of the list by the number of elements in [collection].
   * Throws an [UnsupportedError] if this list is not
   * extendable.
   */
  void addAll(Collection<E> collection);

  /**
   * Sorts the list according to the order specified by the [Comparator].
   */
  void sort([Comparator<E> compare = Comparable.compare]);

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
   * Throws an [IndexOutOfRangeException] if the [index] does not point inside
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
   * Returns the last element of the list, or throws an out of bounds
   * exception if the list is empty.
   */
  E get last;

  /**
   * Returns a new list containing [length] elements from the list,
   * starting at  [start].
   * Returns an empty list if [length] is 0.
   * Throws an [ArgumentError] if [length] is negative.
   * Throws an [IndexOutOfRangeException] if [start] or
   * [:start + length - 1:] are out of range.
   */
  List<E> getRange(int start, int length);

  /**
   * Copies [length] elements of [from], starting
   * at [startFrom], into the list, starting at [start].
   * If [length] is 0, this method does not do anything.
   * Throws an [ArgumentError] if [length] is negative.
   * Throws an [IndexOutOfRangeException] if [start] or
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
   * Throws an [IndexOutOfRangeException] if [start] or
   * [:start + length: - 1] are out of range.
   */
  void removeRange(int start, int length);

  /**
   * Inserts a new range into the list, starting from [start] to
   * [:start + length - 1:]. The entries are filled with [initialValue].
   * Throws an [UnsupportedError] if the list is
   * not extendable.
   * If [length] is 0, this method does not do anything.
   * If [start] is the length of the list, this method inserts the
   * range at the end of the list.
   * Throws an [ArgumentError] if [length] is negative.
   * Throws an [IndexOutOfRangeException] if [start] is negative or if
   * [start] is greater than the length of the list.
   */
  void insertRange(int start, int length, [E initialValue]);
}

class _ListImpl<E> {
  /**
   * Factory implementation of List().
   *
   * Creates a list of the given [length].
   */
  external factory List([int length]);

  /**
   * Factory implementation of List.from().
   *
   * Creates a list with the elements of [other]. The order in
   * the list will be the order provided by the iterator of [other].
   */
  external factory List.from(Iterable<E> other);
}
