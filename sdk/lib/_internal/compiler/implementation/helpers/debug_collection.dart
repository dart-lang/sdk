// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.helpers;

typedef void DebugCallback(String methodName, var arg1, var arg2);

class DebugMap<K, V> implements Map<K, V> {
  final Map<K, V> map;
  DebugCallback indexSetCallBack;
  DebugCallback putIfAbsentCallBack;

  DebugMap(this.map, {DebugCallback addCallback}) {
    if (addCallback != null) {
      this.addCallback = addCallback;
    }
  }

  void set addCallback(DebugCallback value) {
    indexSetCallBack = value;
    putIfAbsentCallBack = value;
  }

  bool containsValue(Object value) {
    return map.containsValue(value);
  }

  bool containsKey(Object key) => map.containsKey(key);

  V operator [](Object key) => map[key];

  void operator []=(K key, V value) {
    if (indexSetCallBack != null) {
      indexSetCallBack('[]=', key, value);
    }
    map[key] = value;
  }

  V putIfAbsent(K key, V ifAbsent()) {
    return map.putIfAbsent(key, () {
      V v = ifAbsent();
      if (putIfAbsentCallBack != null) {
        putIfAbsentCallBack('putIfAbsent', key, v);
      }
      return v;
    });
  }

  void addAll(Map<K, V> other) => map.addAll(other);

  V remove(Object key) => map.remove(key);

  void clear() => map.clear();

  void forEach(void f(K key, V value)) => map.forEach(f);

  Iterable<K> get keys => map.keys;

  Iterable<V> get values => map.values;

  int get length => map.length;

  bool get isEmpty => map.isEmpty;

  bool get isNotEmpty => map.isNotEmpty;
}