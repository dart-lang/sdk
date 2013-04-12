// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

class LinkedHashSet<E> extends _HashSetBase<E> {

  external LinkedHashSet();

  factory LinkedHashSet.from(Iterable<E> iterable) {
    return new LinkedHashSet<E>()..addAll(iterable);
  }

  // Iterable.
  external Iterator<E> get iterator;

  external int get length;

  external bool get isEmpty;

  external bool contains(Object object);

  external void forEach(void action(E element));

  external E get first;

  external E get last;

  E get single {
    if (length == 1) return first;
    var message = (length == 0) ? "No Elements" : "Too many elements";
    throw new StateError(message);
  }

  // Collection.
  external void add(E element);

  external void addAll(Iterable<E> objects);

  external bool remove(Object object);

  external void removeAll(Iterable objectsToRemove);

  external void removeWhere(bool test(E element));

  external void retainWhere(bool test(E element));

  external void clear();

  // Set.
  Set<E> _newSet() => new LinkedHashSet<E>();
}
