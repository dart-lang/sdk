// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

class NegativeLengthList<E> with ListMixin<E> {
  final List<E> _list;

  NegativeLengthList(this._list);

  int get length => _list.length <= 0 ? -1 : _list.length;

  void set length(int value) {
    _list.length = value;
  }

  E operator [](int index) => _list[index];

  void operator []=(int index, E value) {
    _list[index] = value;
  }
}

class NegativeLengthMap<K, V> with MapMixin<K, V> {
  final Map<K, V> _map;

  NegativeLengthMap(this._map);

  int get length => _map.length <= 0 ? -1 : _map.length;

  V? operator [](Object? key) => _map[key];

  void operator []=(K key, V value) {
    _map[key] = value;
  }

  Iterable<K> get keys => _map.keys;

  V? remove(Object? key) => _map.remove(key);

  void clear() => _map.clear();
}

int switchList(List<int> list) => switch (list) {
      [_, _, ...] => 2,
      [_] => 1,
      [] => 0,
    };

int switchMap(Map<int, String> map) => switch (map) {
      {0: _} => 1,
      {} => 0,
      {...} => 2,
    };

main() {
  expect(0, switchList([]));
  expect(1, switchList([0]));
  expect(2, switchList([0, 1]));
  expect(0, switchList(NegativeLengthList([])));
  expect(1, switchList(NegativeLengthList([0])));
  expect(2, switchList(NegativeLengthList([0, 1])));

  expect(0, switchMap({}));
  expect(1, switchMap({0: ''}));
  expect(2, switchMap({1: ''}));
  expect(0, switchMap(NegativeLengthMap({})));
  expect(1, switchMap(NegativeLengthMap({0: ''})));
  expect(2, switchMap(NegativeLengthMap({1: ''})));
}

expect(expected, actual) {
  if (expected != actual) throw 'Expected $expected, actual $actual';
}
