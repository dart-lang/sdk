// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.util.emptyset;

import 'dart:collection' show IterableBase;

class ImmutableEmptySet<E> extends IterableBase<E> implements Set<E> {
  const ImmutableEmptySet();

  Set<R> cast<R>() => new ImmutableEmptySet<R>();

  @Deprecated("Use cast instead.")
  Set<R> retype<R>() => cast<R>();

  get iterator => const _EmptySetIterator();
  int get length => 0;
  bool get isEmpty => true;

  get _immutableError => throw new UnsupportedError("EmptySet is immutable");

  bool add(E element) => _immutableError;
  void addAll(Iterable<E> elements) => _immutableError;

  E lookup(Object element) => null;
  bool remove(Object element) => false;
  void removeAll(Iterable<Object> elements) {}
  void removeWhere(bool test(E element)) {}
  void retainAll(Iterable<Object> elements) {}
  void retainWhere(bool test(E element)) {}
  void forEach(void action(E element)) {}
  void clear() {}

  bool contains(Object element) => false;
  bool containsAll(Iterable<Object> other) => other.isEmpty;

  Set<E> union(Set<E> other) => new Set.from(other);
  Set<E> intersection(Set<Object> other) => this;
  Set<E> difference(Set<Object> other) => this;
  Set<E> toSet() => new Set<E>();
}

class _EmptySetIterator implements Iterator<Null> {
  const _EmptySetIterator();

  Null get current => null;
  bool moveNext() => false;
}
