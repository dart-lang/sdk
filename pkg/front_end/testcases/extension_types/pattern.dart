// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type MyList<T>(List<T> it) implements List<T> {}

extension type MyMap<K, V>(Map<K, V> it) implements Map<K, V> {}

method(MyList<int> list, MyMap<String, bool> map) {
  var [a] = list;
  var {'foo': b} = map;
  if (list case [var c]) {}
  if (map case {'foo': var d}) {}
  switch (list) {
    case [var e] when e > 5:
    case [_, var e] when e < 5:
      print(e);
  }
  switch (map) {
    case {1: var e}:
      print(e);
  }
}