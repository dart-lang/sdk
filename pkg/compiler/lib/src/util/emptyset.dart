// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.util.emptyset;

import 'dart:collection' show IterableBase;

class ImmutableEmptySet<E> extends IterableBase<E> implements Set<E> {
  const ImmutableEmptySet();

  @override
  Set<R> cast<R>() => new ImmutableEmptySet<R>();
  @override
  get iterator => const _EmptySetIterator();
  @override
  int get length => 0;
  @override
  bool get isEmpty => true;

  get _immutableError => throw new UnsupportedError("EmptySet is immutable");

  @override
  bool add(E element) => _immutableError;
  @override
  void addAll(Iterable<E> elements) => _immutableError;

  @override
  E lookup(Object element) => null;
  @override
  bool remove(Object element) => false;
  @override
  void removeAll(Iterable<Object> elements) {}
  @override
  void removeWhere(bool test(E element)) {}
  @override
  void retainAll(Iterable<Object> elements) {}
  @override
  void retainWhere(bool test(E element)) {}
  @override
  void forEach(void action(E element)) {}
  @override
  void clear() {}

  @override
  bool contains(Object element) => false;
  @override
  bool containsAll(Iterable<Object> other) => other.isEmpty;

  @override
  Set<E> union(Set<E> other) => new Set.from(other);
  @override
  Set<E> intersection(Set<Object> other) => this;
  @override
  Set<E> difference(Set<Object> other) => this;
  @override
  Set<E> toSet() => new Set<E>();
}

class _EmptySetIterator implements Iterator<Null> {
  const _EmptySetIterator();

  @override
  Null get current => null;
  @override
  bool moveNext() => false;
}
