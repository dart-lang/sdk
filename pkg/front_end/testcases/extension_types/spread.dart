// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type MyList<T>(List<T> it) implements List<T> {}

extension type MySet<T>(Set<T> it) implements Set<T> {}

extension type MyMap<K, V>(Map<K, V> it) implements Map<K, V> {}

method(MyList<int> list, MySet<String> set, MyMap<bool, num> map) {
  var list2 = [...list];
  var set2 = {...set};
  var map2 = {...map};
}

test() {
  MyList<int> list = []; // Error
  MySet<String> set = {}; // Error
  MyMap<String, bool> map = {}; // Error
}