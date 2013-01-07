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
}

/**
 * An unmodifiable [List].
 */
abstract class NonExtensibleListMixin<E>
    extends Iterable<E> implements List<E> {

  Iterator<E> get iterator => new ListIterator(this);

  void forEach(f(E element)) {
    for (int i = 0; i < this.length; i++) f(this[i]);
  }

  bool contains(E value) {
    for (int i = 0; i < length; i++) {
      if (this[i] == value) return true;
    }
    return false;
  }

  reduce(initialValue, combine(previousValue, E element)) {
    var value = initialValue;
    for (int i = 0; i < this.length; i++) {
      value = combine(value, this[i]);
    }
    return value;
  }

  bool every(bool f(E element)) {
    for (int i = 0; i < this.length; i++) {
      if (!f(this[i])) return false;
    }
    return true;
  }

  bool any(bool f(E element)) {
    for (int i = 0; i < this.length; i++) {
      if (f(this[i])) return true;
    }
    return false;
  }

  bool get isEmpty {
    return this.length == 0;
  }

  E elementAt(int index) {
    return this[index];
  }

  int indexOf(E value, [int start = 0]) {
    for (int i = start; i < length; i++) {
      if (this[i] == value) return i;
    }
    return -1;
  }

  int lastIndexOf(E value, [int start]) {
    if (start == null) start = length - 1;
    for (int i = start; i >= 0; i--) {
      if (this[i] == value) return i;
    }
    return -1;
  }

  E get first {
    if (length > 0) return this[0];
    throw new StateError("No elements");
  }

  E get last {
    if (length > 0) return this[length - 1];
    throw new StateError("No elements");
  }

  E get single {
    if (length == 1) return this[0];
    if (length == 0) throw new StateError("No elements");
    throw new StateError("More than one element");
  }

  List<E> getRange(int start, int length) {
    List<E> result = <E>[];
    for (int i = 0; i < length; i++) {
      result.add(this[start + i]);
    }
    return result;
  }

  void operator []=(int index, E value) {
    throw new UnsupportedError(
        "Cannot modify an unmodifiable list");
  }

  void set length(int newLength) {
    throw new UnsupportedError(
        "Cannot change the length of an unmodifiable list");
  }

  void add(E value) {
    throw new UnsupportedError(
        "Cannot add to an unmodifiable list");
  }

  void addLast(E value) {
    throw new UnsupportedError(
        "Cannot add to an unmodifiable list");
  }

  void addAll(Iterable<E> iterable) {
    throw new UnsupportedError(
        "Cannot add to an unmodifiable list");
  }

  void sort([Comparator<E> compare]) {
    throw new UnsupportedError(
        "Cannot modify an unmodifiable list");
  }

  void clear() {
    throw new UnsupportedError(
        "Cannot clear an unmodifiable list");
  }

  E removeAt(int index) {
    throw new UnsupportedError(
        "Cannot remove in an unmodifiable list");
  }

  E removeLast() {
    throw new UnsupportedError(
        "Cannot remove in an unmodifiable list");
  }

  void setRange(int start, int length, List<E> from, [int startFrom]) {
    throw new UnsupportedError(
        "Cannot modify an unmodifiable list");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedError(
        "Cannot remove in an unmodifiable list");
  }

  void insertRange(int start, int length, [E initialValue]) {
    throw new UnsupportedError(
        "Cannot insert range in an unmodifiable list");
  }
}

/**
 * Iterates over a [Sequence] in growing index order.
 */
class ListIterator<E> implements Iterator<E> {
  final List<E> _list;
  int _position;
  E _current;

  ListIterator(this._list) : _position = -1;

  bool moveNext() {
    int nextPosition = _position + 1;
    if (nextPosition < _list.length) {
      _current = _list[nextPosition];
      _position = nextPosition;
      return true;
    }
    _position = _list.length;
    _current = null;
    return false;
  }

  E get current => _current;
}

class MappedList<S, T> extends NonExtensibleListMixin<T> {
  final List<S> _list;
  final _Transformation<S, T> _f;

  MappedList(this._list, T this._f(S element));

  T operator[](int index) => _f(_list[index]);
  int get length => _list.length;
}

/**
 * An immutable view of a [List].
 */
class ListView<E> extends NonExtensibleListMixin<E> {
  final List<E> _list;
  final int _offset;
  final int _length;

  /**
   * If the given length is `null` then the ListView's length is bound by
   * the backed [list].
   */
  ListView(List<E> list, this._offset, this._length) : _list = list {
    if (_offset is! int || _offset < 0) {
      throw new ArgumentError(_offset);
    }
    if (_length != null &&
        (_length is! int || _length < 0)) {
      throw new ArgumentError(_length);
    }
  }

  int get length {
    int originalLength = _list.length;
    int skipLength = originalLength - _offset;
    if (skipLength < 0) return 0;
    if (_length == null || _length > skipLength) return skipLength;
    return _length;
  }

  E operator[](int index) {
    int skipIndex = index + _offset;
    if (index < 0 ||
        (_length != null && index >= _length) ||
        index + _offset >= _list.length) {
      throw new RangeError.value(index);
    }
    return _list[index + _offset];
  }

  ListView<E> skip(int skipCount) {
    if (skipCount is! int || skipCount < 0) {
      throw new ArgumentError(skipCount);
    }
    return new ListView(_list, _offset + skipCount, _length);
  }

  ListView<E> take(int takeCount) {
    if (takeCount is! int || takeCount < 0) {
      throw new ArgumentError(takeCount);
    }
    int newLength = takeCount;
    if (_length != null && takeCount > _length) newLength = _length;
    return new ListView(_list, _offset, newLength);
  }
}
