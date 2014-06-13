// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.dom.html;

abstract class ImmutableListMixin<E> implements List<E> {
  // From Iterable<$E>:
  Iterator<E> get iterator {
    // Note: NodeLists are not fixed size. And most probably length shouldn't
    // be cached in both iterator _and_ forEach method. For now caching it
    // for consistency.
    return new FixedSizeListIterator<E>(this);
  }

  // From Collection<E>:
  void add(E value) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void addAll(Iterable<E> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  // From List<E>:
  void sort([int compare(E a, E b)]) {
    throw new UnsupportedError("Cannot sort immutable List.");
  }

  void shuffle([Random random]) {
    throw new UnsupportedError("Cannot shuffle immutable List.");
  }

  void insert(int index, E element) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void insertAll(int index, Iterable<E> iterable) {
    throw new UnsupportedError("Cannot add to immutable List.");
  }

  void setAll(int index, Iterable<E> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  E removeAt(int pos) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  E removeLast() {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  bool remove(Object object) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void removeWhere(bool test(E element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void retainWhere(bool test(E element)) {
    throw new UnsupportedError("Cannot remove from immutable List.");
  }

  void setRange(int start, int end, Iterable<E> iterable, [int skipCount = 0]) {
    throw new UnsupportedError("Cannot setRange on immutable List.");
  }

  void removeRange(int start, int end) {
    throw new UnsupportedError("Cannot removeRange on immutable List.");
  }

  void replaceRange(int start, int end, Iterable<E> iterable) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }

  void fillRange(int start, int end, [E fillValue]) {
    throw new UnsupportedError("Cannot modify an immutable List.");
  }
}
