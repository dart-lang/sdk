// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class MapLike<K, V> {
  final Map<K, V> _map = {};

  V get(Object key) => _map[key];
  V put(K key, V value) => _map[key] = value;
}

extension Extension<K, V> on MapLike<K, V> {
  V operator [](Object key) => get(key);
  void operator []=(K key, V value) => put(key, value);
}

main() {
  MapLike<int, String> map1 = new MapLike();
  expect(null, map1[0]);
  map1.put(0, '0');
  expect('0', map1[0]);
  expect(null, map1[1]);
  expect('1', map1[1] = '1');
  expect('1', map1[1]);
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}