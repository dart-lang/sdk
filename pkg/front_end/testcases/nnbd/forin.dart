// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// The test checks that only subtypes of Iterable<dynamic> and "dynamic" are
// allowed as the iterable in a for-in loop.

error(Iterable<int>? i2, List<int>? l2, Object o1, Object? o2) {
  for (int x in i2) x;
  [for (int x in i2) x];

  for (int x in l2) x;
  [for (int x in l2) x];

  for (int x in o1) x;
  [for (int x in o1) x];

  for (int x in o2) x;
  [for (int x in o2) x];
}

ok(Iterable<int> i1, List<int> l1, dynamic d) {
  for (int x in i1) x;
  [for (int x in i1) x];

  for (int x in l1) x;
  [for (int x in l1) x];

  for (int x in d) x;
  [for (int x in d) x];
}

main() {}
