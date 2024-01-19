// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

import 'package:expect/expect.dart';

extension type MyList<T>(List<T> it) implements List<T> {}

extension type MySet<T>(Set<T> it) implements Set<T> {}

extension type MyMap<K, V>(Map<K, V> it) implements Map<K, V> {}

List<T> copyList<T>(MyList<T> list) {
  var copy = [...list];
  return copy;
}


Set<T> copySet<T>(MySet<T> set) {
  var copy = {...set};
  return copy;
}


Map<K, V> copyMap<K, V>(MyMap<K, V> map) {
  var copy = {...map};
  return copy;
}

main() {
  MyList<int> list = MyList([1, 2, 3]);
  Expect.deepEquals(list , copyList(list));

  MySet<int> set = MySet({1, 2, 3});
  Expect.deepEquals(set , copySet(set));

  MyMap<int, bool> map = MyMap({1: true, 2: false, 3: true});
  Expect.deepEquals(map , copyMap(map));
}