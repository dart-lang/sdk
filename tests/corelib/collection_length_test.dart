// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library map_test;

import 'dart:collection';

// Test that length/isEmpty opertions are constant time on
// maps, strings and collections.

void testString(int n) {
  String s = "x";
  String string = "";
  int length = n;
  while (true) {
    if ((length & 1) == 1) {
      string += s;
    }
    length >>= 1;
    if (length == 0) break;
    s += s;
  }
  testLength(string, n);
  testLength(string.codeUnits, n);
}

void testMap(Map map, int n) {
  for (int i = 0; i < n; i++) {
    map[i] = i;
  }
  testLength(map, n);
  testLength(map.keys, n);
  testLength(map.values, n);
}

void testCollection(var collection, n) {
  for (int i = 0; i < n; i++) {
    collection.add(i);
  }
  testLength(collection, n);
}

void testList(List list, n) {
  // Works even if list is fixed-length.
  for (int i = 0; i < n; i++) {
    list[i] = i;
  }
  testLength(list, n);
}

void testLength(var lengthable, int size) {
  print(lengthable.runtimeType); // Show what hangs the test.
  int length = 0;
  // If length, isEmpty or isNotEmpty is not a constant-time (or very fast)
  // operation, this will timeout.
  for (int i = 0; i < 100000; i++) {
    if (!lengthable.isEmpty) length += lengthable.length;
    if (lengthable.isNotEmpty) length += lengthable.length;
  }
  if (length != size * 200000) throw "Bad length: $length / size: $size";
}

main() {
  const int N = 100000;
  testMap(new HashMap(), N);
  testMap(new LinkedHashMap(), N);
  testMap(new SplayTreeMap(), N);
  testCollection(new HashSet(), N);
  testCollection(new LinkedHashSet(), N);
  testCollection(new ListQueue(), N);
  testCollection(new DoubleLinkedQueue(), N);
  testList(new List()..length = N, N);
  testList(new List(N), N);
  testString(N);
}
