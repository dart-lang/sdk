// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.util.emptyset;

import 'dart:collection' show IterableBase;

class ImmutableEmptySet<E> extends IterableBase<E> implements Set<E> {
  const ImmutableEmptySet();

  get iterator => const _EmptySetIterator();
  int get length => 0;
  bool get isEmpty => true;

  get _immutableError => throw new UnsupportedError("EmptySet is immutable");

  bool add (E element) => _immutableError;
  void addAll(Iterable<E> elements) => _immutableError;

  E lookup(E element) => null;
  bool remove(E element) => false;
  void removeAll(Iterable<E> elements) {}
  void removeWhere(bool test(E element)) {}
  void retainAll(Iterable<E> elements) {}
  void retainWhere(bool test(E element)) {}
  void forEach(void action(E element)) {}
  void clear() {}

  bool contains(E element) => false;
  bool containsAll(Iterable<E> other) => other.isEmpty;

  Set<E> union(Set<E> other) => new Set.from(other);
  Set<E> intersection(Set<E> other) => this;
  Set<E> difference(Set<E> other) => this;
  Set<E> toSet() => new Set();
}

class _EmptySetIterator<E> implements Iterator<E> {
  const _EmptySetIterator();

  E get current => null;
  bool moveNext() => false;
}
