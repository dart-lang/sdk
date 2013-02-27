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
abstract class ListBase<E> extends ListIterable<E> implements List<E> {
  // List interface.
  int get length;
  E operator[](int index);

  // Collection interface.
  // Implement in a fully mutable specialized class if necessary.
  // The fixed-length and unmodifiable lists throw on all members
  // of the collection interface.

  // Iterable interface.
  E elementAt(int index) {
    return this[index];
  }
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

/**
 * An [Iterable] of the UTF-16 code units of a [String] in index order.
 */
class CodeUnits extends UnmodifiableListBase<int> {
  /** The string that this is the code units of. */
  String _string;

  CodeUnits(this._string);

  int get length => _string.length;
  int operator[](int i) => _string.codeUnitAt(i);
}
