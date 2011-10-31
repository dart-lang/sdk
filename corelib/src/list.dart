// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A [List] is an indexable collection with a length. It can be of
 * fixed size or extendable.
 */
interface List<E> extends Collection<E> factory ListFactory {

  /**
   * Creates a list of the given [length].
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
   * an [UnsupportedOperationException] if the list is not extendable.
   */
  void set length(int newLength);

  /**
   * Adds [value] at the end of the list, extending the length by
   * one. Throws an [UnsupportedOperationException] if the list is not
   * extendable.
   */
  void add(E value);

  /**
   * Adds [value] at the end of the list, extending the length by
   * one. Throws an [UnsupportedOperationException] if the list is not
   * extendable.
   */
  void addLast(E value);

  /**
   * Appends all elements of the [collection] to the end of list.
   * Extends the length of the list by the length of [collection].
   * Throws an [UnsupportedOperationException] if the list is not
   * extendable.
   */
  void addAll(Collection<E> collection);

  /**
   * Sorts the list according to the order specified by the comparator.
   * The order specified by the comparator must be reflexive,
   * anti-symmetric, and transitive.
   *
   * The comparator function [compare] must take two arguments [a] and [b]
   * and return
   *
   *   an integer strictly less than 0 if a < b,
   *   0 if a = b, and
   *   an integer strictly greater than 0 if a > b.
   */
  void sort(int compare(E a, E b));

  /**
   * Returns the first index of [element] in this list. Searches this
   * list from index [start] to the length of the list. Returns
   * -1 if [element] is not found.
   */
  int indexOf(E element, [int start]);

  /**
   * Returns the last index of [element] in this list. Searches this
   * list from index [start] (inclusive) to 0. Returns -1 if
   * [element] is not found.
   */
  int lastIndexOf(E element, [int start]);

  /**
   * Removes all elements in the list. The length of the list
   * becomes zero. Throws an [UnsupportedOperationException] if
   * the list is not extendable.
   */
  void clear();

  /**
   * Pops and returns the last element of the list.
   * Throws a [UnsupportedOperationException] if the length of the
   * list cannot be changed.
   */
  E removeLast();

  /**
   * Returns the last element of the list, or throws an out of bounds
   * exception if the list is empty.
   */
  E last();

  /**
   * Returns a sub list copy of this list, from [start] to
   * [:start + length:].
   * Returns an empty list if [length] is 0.
   * Throws an [IllegalArgumentException] if [length] is negative.
   * Throws an [IndexOutOfRangeException] if [start] or
   * [:start + length:] are out of range.
   */
  List<E> getRange(int start, int length);

  /**
   * Copies [length] elements of the [from] array, starting
   * from [startFrom], into [:this:], starting at [start].
   * Throws an [UnsupportedOperationException] if the list is
   * not extendable.
   * If [length] is 0, this method does not do anything.
   * Throws an [IllegalArgumentException] if [length] is negative.
   * Throws an [IndexOutOfRangeException] if [start] or
   * [:start + length:] are out of range for [:this:], or if
   * [startFrom] is out of range for [from].
   */
  void setRange(int start, int length, List<E> from, [int startFrom]);

  /**
   * Removes the range in the list starting from [start] to
   * [:start + length:].
   * Throws an [UnsupportedOperationException] if the list is
   * not extendable.
   * If [length] is 0, this method does not do anything.
   * Throws an [IllegalArgumentException] if [length] is negative.
   * Throws an [IndexOutOfRangeException] if [start] or
   * [:start + length:] are out of range.
   */
  void removeRange(int start, int length);

  /**
   * Inserts a new range in the list, starting from [start] to
   * [:start + length:]. The entries are filled with [initialValue].
   * Throws an [UnsupportedOperationException] if the list is
   * not extendable.
   * If [length] is 0, this method does not do anything.
   * If [start] is the length of the array, this method inserts the
   * range at the end of the array.
   * Throws an [IllegalArgumentException] if [length] is negative.
   * Throws an [IndexOutOfRangeException] if [start] or
   * [:start + length:] are out of range.
   */
  void insertRange(int start, int length, [E initialValue]);
}
