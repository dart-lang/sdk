// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

class LinkedHashSet<E> extends _HashSetBase<E> {
  static const int _INITIAL_CAPACITY = 8;
  _LinkedHashTable<E> _table;

  LinkedHashSet() : _table = new _LinkedHashTable(_INITIAL_CAPACITY) {
    _table._container = this;
  }

  factory LinkedHashSet.from(Iterable<E> iterable) {
    return new LinkedHashSet<E>()..addAll(iterable);
  }

  // Iterable.
  Iterator<E> get iterator => new _LinkedHashTableKeyIterator<E>(_table);

  int get length => _table._elementCount;

  bool get isEmpty => _table._elementCount == 0;

  bool contains(Object object) => _table._get(object) >= 0;

  void forEach(void action(E element)) {
    int offset = _table._next(_LinkedHashTable._HEAD_OFFSET);
    int modificationCount = _table._modificationCount;
    while (offset != _LinkedHashTable._HEAD_OFFSET) {
      E key = _table._key(offset);
      action(key);
      _table._checkModification(modificationCount);
      offset = _table._next(offset);
    }
  }

  E get first {
    int firstOffset = _table._next(_LinkedHashTable._HEAD_OFFSET);
    if (firstOffset == _LinkedHashTable._HEAD_OFFSET) {
      throw new StateError("No elements");
    }
    return _table._key(firstOffset);
  }

  E get last {
    int lastOffset = _table._prev(_LinkedHashTable._HEAD_OFFSET);
    if (lastOffset == _LinkedHashTable._HEAD_OFFSET) {
      throw new StateError("No elements");
    }
    return _table._key(lastOffset);
  }

  E get single {
    int firstOffset = _table._next(_LinkedHashTable._HEAD_OFFSET);
    if (firstOffset == _LinkedHashTable._HEAD_OFFSET) {
      throw new StateError("No elements");
    }
    int lastOffset = _table._prev(_LinkedHashTable._HEAD_OFFSET);
    if (lastOffset != firstOffset) {
      throw new StateError("Too many elements");
    }
    return _table._key(firstOffset);
  }

  // Collection.
  void _filterWhere(bool test(E element), bool removeMatching) {
    int entrySize = _table._entrySize;
    int length = _table._table.length;
    int offset = _table._next(_LinkedHashTable._HEAD_OFFSET);
    while (offset != _LinkedHashTable._HEAD_OFFSET) {
      E key = _table._key(offset);
      int nextOffset = _table._next(offset);
      int modificationCount = _table._modificationCount;
      bool shouldRemove = (removeMatching == test(key));
      _table._checkModification(modificationCount);
      if (shouldRemove) {
        _table._deleteEntry(offset);
      }
      offset = nextOffset;
    }
    _table._checkCapacity();
  }

  void add(E element) {
    _table._put(element);
    _table._checkCapacity();
  }

  bool remove(Object object) {
    int offset = _table._remove(object);
    if (offset >= 0) {
      _table._checkCapacity();
      return true;
    }
    return false;
  }

  void removeAll(Iterable objectsToRemove) {
    for (Object object in objectsToRemove) {
      if (_table.remove(object) >= 0) {
        _table._checkCapacity();
      }
    }
  }

  void retainAll(Iterable objectsToRetain) {
    Set retainSet;
    if (objectsToRetain is Set) {
      retainSet = objectsToRetain;
    } else {
      retainSet = objectsToRetain.toSet();
    }
    _filterWhere(retainSet.contains, false);
  }

  void removeWhere(bool test(E element)) {
    _filterWhere(test, true);
  }

  retianWhere(bool test(E element)) {
    _filterWhere(test, false);
  }

  // Set
  Set<E> _newSet() => new LinkedHashSet<E>();
}
