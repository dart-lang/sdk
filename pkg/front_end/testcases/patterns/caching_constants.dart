// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

bool get hasUnsoundNullSafety => const <Null>[] is List<Object>;

class MyMap<K, V> with MapMixin<K, V> {
  int containsKeyCount = 0;
  int indexGetCount = 0;

  final Map<K, V> _map;

  MyMap(this._map);

  bool containsKey(Object? key) {
    containsKeyCount++;
    return _map.containsKey(key);
  }

  V? operator [](Object? key) {
    indexGetCount++;
    return _map[key];
  }

  void operator []=(K key, V value) => _map[key] = value;

  void clear() => _map.clear();

  Iterable<K> get keys => _map.keys;

  V? remove(Object? key) => _map.remove(key);
}

int method(Map<int, String?> m) {
  switch (m) {
    case {1: 'foo'}:
      return 0;
    case {1: 'bar'}:
      return 1;
  }
  return 2;
}

test(Map<int, String> map,
    {required int expectedValue,
    required int expectedContainsKeyCount,
    required int expectedIndexGetCount}) {
  MyMap<int, String> myMap = new MyMap(map);
  expect(expectedValue, method(myMap), 'Unexpected value for $map.');
  expect(expectedContainsKeyCount, myMap.containsKeyCount,
      'Unexpected containsKey count for $map.');
  expect(expectedIndexGetCount, myMap.indexGetCount,
      'Unexpected indexGet count for $map.');
}

main() {
  test({0: 'foo'},
      expectedValue: 2,
      expectedContainsKeyCount: 1,
      expectedIndexGetCount: hasUnsoundNullSafety ? 0 : 1);
  test({1: 'foo'},
      expectedValue: 0,
      expectedContainsKeyCount: hasUnsoundNullSafety ? 1 : 0,
      expectedIndexGetCount: 1);
  test({1: 'bar'},
      expectedValue: 1,
      expectedContainsKeyCount: hasUnsoundNullSafety ? 1 : 0,
      expectedIndexGetCount: 1);
  test({1: 'baz'},
      expectedValue: 2,
      expectedContainsKeyCount: hasUnsoundNullSafety ? 1 : 0,
      expectedIndexGetCount: 1);
}

expect(expected, actual, message) {
  if (expected != actual) throw '$message Expected $expected, actual $actual';
}
