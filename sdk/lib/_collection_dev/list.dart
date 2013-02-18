// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart._collection.dev;

/**
 * Class implementing the read-operations on [List].
 *
 * Implements all read-only operations, except [:operator[]:] and [:length:],
 * in terms of those two operations.
 */
abstract class ListBase<E> extends Collection<E> implements List<E> {
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

  Iterable map(f(E element)) {
    return new MappedIterable(this, f);
  }

  Iterable<E> take(int n) {
    return new SubListIterable(this, 0, n);
  }

  Iterable<E> skip(int n) {
    return new SubListIterable(this, n, null);
  }

  Iterable<E> get reversed => new ReversedListIterable(this);

  String toString() => ToString.collectionToString(this);
}

/**
 * Abstract class implementing the non-length changing operations of [List].
 *
 * All modifications are performed using [[]=].
 */
abstract class FixedLengthListBase<E> extends ListBase<E> {
  void operator[]=(int index, E value);

  void sort([Comparator<E> compare]) {
    Sort.sort(this, compare);
  }

  void setRange(int start, int length, List<E> from, [int startFrom]) {
    if (length < 0) throw new ArgumentError("length: $length");
    if (startFrom == null) startFrom = 0;
    for (int i = 0; i < length; i++) {
      this[start + i] = from[startFrom + i];
    }
  }

  void set length(int newLength) {
    throw new UnsupportedError(
        "Cannot change the length of a fixed-length list");
  }

  void add(E value) {
    throw new UnsupportedError(
        "Cannot add to a fixed-length list");
  }

  void addLast(E value) {
    throw new UnsupportedError(
        "Cannot add to a fixed-length list");
  }

  void addAll(Iterable<E> iterable) {
    throw new UnsupportedError(
        "Cannot add to a fixed-length list");
  }

  void remove(E element) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void removeMatching(bool test(E element)) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void clear() {
    throw new UnsupportedError(
        "Cannot clear a fixed-length list");
  }

  E removeAt(int index) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  E removeLast() {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedError(
        "Cannot remove from a fixed-length list");
  }

  void insertRange(int start, int length, [E initialValue]) {
    throw new UnsupportedError(
        "Cannot insert range in a fixed-length list");
  }
}

/**
 * An unmodifiable [List].
 */
abstract class UnmodifiableListBase<E> extends ListBase<E> {

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

  void remove(E element) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  void removeAll(Iterable elements) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  void retainAll(Iterable elements) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  void removeMatching(bool test(E element)) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
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
        "Cannot remove from an unmodifiable list");
  }

  E removeLast() {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  void setRange(int start, int length, List<E> from, [int startFrom]) {
    throw new UnsupportedError(
        "Cannot modify an unmodifiable list");
  }

  void removeRange(int start, int length) {
    throw new UnsupportedError(
        "Cannot remove from an unmodifiable list");
  }

  void insertRange(int start, int length, [E initialValue]) {
    throw new UnsupportedError(
        "Cannot insert range in an unmodifiable list");
  }
}

/** An empty fixed-length list. */
class EmptyList<E> extends FixedLengthListBase<E> {
  int get length => 0;
  E operator[](int index) { throw new RangeError.value(index); }
  void operator []=(int index, E value) { throw new RangeError.value(index); }
  Iterable<E> skip(int count) => const EmptyIterable();
  Iterable<E> take(int count) => const EmptyIterable();
  Iterable<E> get reversed => const EmptyIterable();
  void sort([int compare(E a, E b)]) {}
}

class ReversedListIterable<E> extends ListIterable<E> {
  Iterable<E> _source;
  ReversedListIterable(this._source);

  int get length => _source.length;

  E elementAt(int index) => _source.elementAt(_source.length - 1 - index);
}
