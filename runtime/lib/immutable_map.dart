// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Immutable map class for compiler generated map literals.

class ImmutableMap<K, V> implements Map<K, V> {
  final ImmutableArray kvPairs_;

  const ImmutableMap._create(ImmutableArray keyValuePairs)
      : kvPairs_ = keyValuePairs;


  V operator [](K key) {
    // TODO(hausner): Since the keys are sorted, we could do a binary
    // search. But is it worth it?
    for (int i = 0; i < kvPairs_.length - 1; i += 2) {
      if (key == kvPairs_[i]) {
        return kvPairs_[i+1];
      }
    }
    return null;
  }

  bool isEmpty() {
    return kvPairs_.length === 0;
  }

  int get length {
    return kvPairs_.length ~/ 2;
  }

  void forEach(void f(K key, V value)) {
    for (int i = 0; i < kvPairs_.length; i += 2) {
      f(kvPairs_[i], kvPairs_[i+1]);
    }
  }

  Collection<K> getKeys() {
    int numKeys = length;
    List<K> list = new List<K>(numKeys);
    for (int i = 0; i < numKeys; i++) {
      list[i] = kvPairs_[i*2];
    }
    return list;
  }

  Collection<V> getValues() {
    int numValues = length;
    List<V> list = new List<V>(numValues);
    for (int i = 0; i < numValues; i++) {
      list[i] = kvPairs_[i*2 + 1];
    }
    return list;
  }

  bool containsKey(K key) {
    for (int i = 0; i < kvPairs_.length; i += 2) {
      if (key == kvPairs_[i]) {
        return true;
      }
    }
    return false;
  }

  bool containsValue(V value) {
    for (int i = 1; i < kvPairs_.length; i += 2) {
      if (value == kvPairs_[i]) {
        return true;
      }
    }
    return false;
  }

  void operator []=(K key, V value) {
    throw const IllegalAccessException();
  }

  V putIfAbsent(K key, V ifAbsent()) {
    throw const IllegalAccessException();
  }

  void clear() {
    throw const IllegalAccessException();
  }

  V remove(K key) {
    throw const IllegalAccessException();
  }

  String toString() {
    return Maps.mapToString(this);
  }
}

