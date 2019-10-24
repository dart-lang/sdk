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
 implicit();
 explicitWithTypeArguments();
 explicitInferredTypeArguments();
}

implicit() {
  MapLike<int, String> map1 = new MapLike();
  expect(null, map1[0]);
  map1.put(0, '0');
  expect('0', map1[0]);
  expect(null, map1[1]);
  map1[1] = '1';
  expect('1', map1[1]);
  expect('2', map1[1] = '2');
  expect('2', map1[1]);
  map1[1] ??= '3';
  expect('2', map1[1]);
  expect('2', map1[1] ??= '4');
  expect('2', map1[1]);
  map1[2] ??= '2';
  expect('2', map1[2]);
  expect('3', map1[3] ??= '3');
  expect('3', map1[3]);

  MapLike<int, int> map2 = new MapLike();
  expect(1, map2[0] = 1);
  expect(3, map2[0] += 2);
  expect(5, map2[0] += 2);
  expect(5, map2[0]++);
  expect(6, map2[0]);
  expect(5, --map2[0]);
  expect(5, map2[0]);
}

explicitWithTypeArguments() {
  MapLike<int, String> map1 = new MapLike();
  expect(null, Extension<int, String>(map1)[0]);
  map1.put(0, '0');
  expect('0', Extension<int, String>(map1)[0]);
  expect(null, Extension<int, String>(map1)[1]);
  Extension<int, String>(map1)[1] = '1';
  expect('1', Extension<int, String>(map1)[1]);
  expect('2', Extension<int, String>(map1)[1] = '2');
  expect('2', Extension<int, String>(map1)[1]);
  Extension<int, String>(map1)[1] ??= '3';
  expect('2', Extension<int, String>(map1)[1]);
  expect('2', Extension<int, String>(map1)[1] ??= '4');
  expect('2', Extension<int, String>(map1)[1]);
  Extension<int, String>(map1)[2] ??= '2';
  expect('2', Extension<int, String>(map1)[2]);
  expect('3', Extension<int, String>(map1)[3] ??= '3');
  expect('3', Extension<int, String>(map1)[3]);

  MapLike<int, int> map2 = new MapLike();
  expect(1, Extension<int, int>(map2)[0] = 1);
  expect(3, Extension<int, int>(map2)[0] += 2);
  expect(5, Extension<int, int>(map2)[0] += 2);
  expect(5, Extension<int, int>(map2)[0]++);
  expect(6, Extension<int, int>(map2)[0]);
  expect(5, --Extension<int, int>(map2)[0]);
  expect(5, Extension<int, int>(map2)[0]);
}

explicitInferredTypeArguments() {
  MapLike<int, String> map1 = new MapLike();
  expect(null, Extension(map1)[0]);
  map1.put(0, '0');
  expect('0', Extension(map1)[0]);
  expect(null, Extension(map1)[1]);
  Extension(map1)[1] = '1';
  expect('1', Extension(map1)[1]);
  expect('2', Extension(map1)[1] = '2');
  expect('2', Extension(map1)[1]);
  Extension(map1)[1] ??= '3';
  expect('2', Extension(map1)[1]);
  expect('2', Extension(map1)[1] ??= '4');
  expect('2', Extension(map1)[1]);
  Extension(map1)[2] ??= '2';
  expect('2', Extension(map1)[2]);
  expect('3', Extension(map1)[3] ??= '3');
  expect('3', Extension(map1)[3]);

  MapLike<int, int> map2 = new MapLike();
  expect(1, Extension(map2)[0] = 1);
  expect(3, Extension(map2)[0] += 2);
  expect(5, Extension(map2)[0] += 2);
  expect(5, Extension(map2)[0]++);
  expect(6, Extension(map2)[0]);
  expect(5, --Extension(map2)[0]);
  expect(5, Extension(map2)[0]);
}

expect(expected, actual) {
  if (expected != actual) {
    throw 'Mismatch: expected=$expected, actual=$actual';
  }
}