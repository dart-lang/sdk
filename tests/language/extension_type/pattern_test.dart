// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=inline-class

import 'package:expect/expect.dart';

extension type MyList<T>(List<T> it) implements List<T> {}

extension type MyMap<K, V>(Map<K, V> it) implements Map<K, V> {}

testListAssignment<T>(MyList<T> list, T value) {
  var [a] = list;
  Expect.equals(value, a);
}

testListIf(MyList<int> list, int value) {
  if (list case [var a]) {
    Expect.equals(value, a);
  } else {
    Expect.equals(value, list.length);
  }
}

testListSwitch(MyList<int> list, int value) {
  switch (list) {
    case [var e] when e > 5:
    case [_, var e] when e < 5:
      Expect.equals(e, value);
    default:
      Expect.equals(list.length, value);
  }
}

testMapAssignment<T>(MyMap<String, T> map, T value) {
  var {'foo': a} = map;
  Expect.equals(value, a);
}

testMapIf(MyMap<String, int> map, int value) {
  if (map case {'foo': var a}) {
    Expect.equals(value, a);
  } else {
    Expect.equals(value, map.length);
  }
}

testMapSwitch(MyMap<String, int> map, int value) {
  switch (map) {
    case {'foo': var e} when e > 5:
    case {'bar': var e} when e < 5:
      Expect.equals(e, value);
    default:
      Expect.equals(map.length, value);
  }
}

main() {
  testListAssignment(MyList<String>(['42']), '42');

  testListIf(MyList<int>([87]), 87);
  testListIf(MyList<int>([]), 0);

  testListSwitch(MyList<int>([6]), 6);
  testListSwitch(MyList<int>([5]), 1);
  testListSwitch(MyList<int>([5, 4]), 4);
  testListSwitch(MyList<int>([6, 7]), 2);

  testMapAssignment(MyMap<String, bool>({'foo': true}), true);

  testMapIf(MyMap<String, int>({'foo': 87}), 87);
  testMapIf(MyMap<String, int>({'bar': 87}), 1);

  testMapSwitch(MyMap<String, int>({'foo': 6}), 6);
  testMapSwitch(MyMap<String, int>({'foo': 5}), 1);
  testMapSwitch(MyMap<String, int>({'bar': 4}), 4);
  testMapSwitch(MyMap<String, int>({'bar': 7}), 1);
}