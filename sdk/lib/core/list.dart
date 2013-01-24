// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.core;

/**
 * A [List] is an indexable collection with a length. It can be of
 * fixed size or extendable.
 */
abstract class List<E> implements Collection<E> {
  /**
   * Creates a list of the given [length].
   *
   * The length of the returned list is not fixed.
   */
  external factory List([int length = 0]);

  /**
   * Creates a fixed-sized list of the given [length] where each entry is
   * filled with [fill].
   */
  external factory List.fixedLength(int length, {E fill: null});

  /**
   * Creates an list of the given [length] where each entry is
   * filled with [fill].
   *
   * The length of the returned list is not fixed.
   */
  external factory List.filled(int length, E fill);

  /**
   * Creates an list with the elements of [other]. The order in
   * the list will be the order provided by the iterator of [other].
   *
   * The length of the returned list is not fixed.
   */
  factory List.from(Iterable other) {
    var list = new List<E>();
    for (E e in other) {
      list.add(e);
    }
    return list;
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
   */
  void addLast(E value);

  /**
   * Appends all elements of the [iterable] to the end of this list.
   * Extends the length of the list by the number of elements in [iterable].
   * Throws an [UnsupportedError] if this list is not extensible.
   */
  void addAll(Iterable<E> iterable);

  /**
   * Returns a reversed fixed-length view of this [List].
   *
   * The reversed list has elements in the opposite order of this list.
   * It is backed by this list, but will stop working if this list
   * becomes shorter than its current length.
   */
  List<E> get reversed;

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
   * Returns a lazy unmodifiable [List] where each element [:e:] of [:this:] is
   * replaced by the result of [:f(e):].
   *
   * This method returns a view of the mapped elements. As long as the
   * returned [List] is not indexed or iterated over, the supplied function [f]
   * will not be invoked. The transformed elements will not be cached. Accessing
   * elements multiple times will invoke the supplied function [f] multiple
   * times.
   */
  List mappedBy(f(E element));

  /**
   * Returns an unmodifiable [List] that hides the first [n] elements.
   *
   * The returned list is a view backed by [:this:].
   *
   * While [:this:] has fewer than [n] elements, then the resulting [List]
   * will be empty.
   */
  List<E> skip(int n);

  /**
   * Returns an unmodifiable [List] with at most [n] elements.
   *
   * The returned list is a view backed by this.
   *
   * The returned [List] may contain fewer than [n] elements, while [:this:]
   * contains fewer than [n] elements.
   */
  List<E> take(int n);
}
