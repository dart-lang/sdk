// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

/// The expensive set is a data structure useful for tracking down
/// excessive memory usage due to large sets. It acts as an ordinary
/// hash set, but it uses 10 times more memory (by default).
class ExpensiveSet<E> extends SetBase<E> {
  final List _sets;

  ExpensiveSet([int copies = 10]) : _sets = new List.filled(copies, null) {
    assert(copies > 0);
    for (int i = 0; i < _sets.length; i++) {
      _sets[i] = new Set<E>();
    }
  }

  @override
  int get length => _sets[0].length;
  @override
  bool get isEmpty => _sets[0].isEmpty;
  @override
  bool get isNotEmpty => _sets[0].isNotEmpty;

  @override
  Iterator<E> get iterator => _sets[0].iterator;

  @override
  bool contains(Object object) => _sets[0].contains(object);
  @override
  E lookup(Object object) => _sets[0].lookup(object);

  @override
  void forEach(void action(E element)) {
    _sets[0].forEach(action);
  }

  @override
  bool add(E element) {
    bool result = _sets[0].add(element);
    for (int i = 1; i < _sets.length; i++) {
      _sets[i].add(element);
    }
    return result;
  }

  @override
  void addAll(Iterable<E> objects) {
    for (E each in objects) {
      add(each);
    }
  }

  @override
  bool remove(Object object) {
    bool result = _sets[0].remove(object);
    for (int i = 1; i < _sets.length; i++) {
      _sets[i].remove(object);
    }
    return result;
  }

  @override
  void clear() {
    for (int i = 0; i < _sets.length; i++) {
      _sets[i].clear();
    }
  }

  @override
  void removeAll(Iterable<Object> objectsToRemove) {
    for (var each in objectsToRemove) {
      remove(each);
    }
  }

  @override
  void removeWhere(bool test(E element)) {
    removeAll(this.toList().where((e) => test(e)));
  }

  @override
  void retainWhere(bool test(E element)) {
    removeAll(toList().where((e) => !test(e)));
  }

  @override
  bool containsAll(Iterable<Object> other) {
    for (Object object in other) {
      if (!this.contains(object)) return false;
    }
    return true;
  }

  Set _newSet() => new ExpensiveSet(_sets.length);

  @override
  Set<E> intersection(Set<Object> other) {
    Set<E> result = _newSet();
    if (other.length < this.length) {
      for (var element in other) {
        if (this.contains(element)) result.add(element);
      }
    } else {
      for (E element in this) {
        if (other.contains(element)) result.add(element);
      }
    }
    return result;
  }

  @override
  Set<E> union(Set<E> other) {
    return _newSet()..addAll(this)..addAll(other);
  }

  @override
  Set<E> difference(Set<Object> other) {
    Set<E> result = _newSet();
    for (E element in this) {
      if (!other.contains(element)) result.add(element);
    }
    return result;
  }

  @override
  void retainAll(Iterable objectsToRetain) {
    Set retainSet;
    if (objectsToRetain is Set) {
      retainSet = objectsToRetain;
    } else {
      retainSet = objectsToRetain.toSet();
    }
    retainWhere(retainSet.contains);
  }

  @override
  Set<E> toSet() {
    var result = new ExpensiveSet<E>(_sets.length);
    for (int i = 0; i < _sets.length; i++) {
      result._sets[i] = _sets[i].toSet();
    }
    return result;
  }

  @override
  String toString() => "expensive(${_sets[0]}x${_sets.length})";
}
