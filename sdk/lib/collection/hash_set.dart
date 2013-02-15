// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

class HashSet<E> extends Collection<E> implements Set<E> {
  static const int _INITIAL_CAPACITY = 8;
  final _HashTable<E> _table;

  HashSet() : _table = new _HashTable(_INITIAL_CAPACITY) {
    _table._container = this;
  }

  factory HashSet.from(Iterable<E> iterable) {
    return new HashSet<E>()..addAll(iterable);
  }

  // Iterable.
  Iterator<E> get iterator => new _HashTableKeyIterator<E>(_table);

  bool get isEmpty => _table._elementCount == 0;

  bool contains(Object object) => _table._get(object) >= 0;

  // Collection.
  void add(E element) {
    _table._put(element);
    _table._checkCapacity();
  }

  void addAll(Iterable<E> objects) {
    for (E object in objects) {
      _table._put(object);
      _table._checkCapacity();
    }
  }

  bool remove(Object object) {
    int offset = _table._remove(object);
    _table._checkCapacity();
    return offset >= 0;
  }

  void removeAll(Iterable objectsToRemove) {
    for (Object object in objectsToRemove) {
      _table._remove(object);
      _table._checkCapacity();
    }
  }

  void retainAll(Iterable objectsToRetain) {
    IterableMixinWorkaround.retainAll(this, objectsToRetain);
  }

  void _filterMatching(bool test(E element), bool removeMatching) {
    int entrySize = _table._entrySize;
    int length = _table._table.length;
    for (int offset =  0; offset < length; offset += entrySize) {
      Object entry = _table._table[offset];
      if (!_table._isFree(entry)) {
        E key = identical(entry, _NULL) ? null : entry;
        int modificationCount = _table._modificationCount;
        bool shouldRemove = (removeMatching == test(key));
        _table._checkModification(modificationCount);
        if (shouldRemove) {
          _table._deleteEntry(offset);
        }
      }
    }
    _table._checkCapacity();
  }

  void removeMatching(bool test(E element)) {
    _filterMatching(test, true);
  }

  void retainMatching(bool test(E element)) {
    _filterMatching(test, false);
  }

  void clear() {
    _table._clear();
  }

  // Set.
  bool isSubsetOf(Collection<E> collection) {
    Set otherSet;
    if (collection is Set) {
      otherSet = collection;
    } else {
      otherSet = collection.toSet();
    }
    return otherSet.containsAll(this);
  }

  bool containsAll(Collection<E> collection) {
    for (E element in collection) {
      if (!this.contains(element)) return false;
    }
    return true;
  }

  Set<E> intersection(Collection<E> other) {
    Set<E> result = new HashSet<E>();
    for (E element in other) {
      if (this.contains(element)) {
        result.add(element);
      }
    }
    return result;
  }

  String toString() =>  Collections.collectionToString(this);
}
