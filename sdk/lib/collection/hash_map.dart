// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart.collection;

class HashMap<K, V> implements Map<K, V> {
  external HashMap();

  factory HashMap.from(Map<K, V> other) {
    return new HashMap<K, V>()..addAll(other);
  }

  external int get length;
  external bool get isEmpty;

  external Iterable<K> get keys;
  external Iterable<V> get values;

  external bool containsKey(K key);
  external bool containsValue(V value);

  external void addAll(Map<K, V> other);

  external V operator [](K key);
  external void operator []=(K key, V value);

  external V putIfAbsent(K key, V ifAbsent());

  external V remove(K key);
  external void clear();

  external void forEach(void action(K key, V value));

  String toString() => Maps.mapToString(this);
}
