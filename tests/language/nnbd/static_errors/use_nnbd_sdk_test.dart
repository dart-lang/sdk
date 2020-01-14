// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import "package:expect/expect.dart";

// SharedOptions=--enable-experiment=non-nullable
void main() {
}

/// These tests will all pass only if run with the NNBD migrated SDK.
/// In not migrated SDK all types are unprefixed, so look non-nullable.
void f(List<int> list, Map<int, String> map, int a, int? b) {
  // List: E operator [](int index);
  list[a]; //# 00: ok
  list[b]; //# 01: compile-time error

  // Map: V? operator [](Object? key);
  map[a]; //# 02: ok
  map[b]; //# 03: ok

  // Map: void operator []=(K key, V value);
  map[a].length; //# 04: compile-time error
  map[a]?.length; //# 05: ok

  map[b] = ''; //# 06: compile-time error
  map[a] = b; //# 07: compile-time error
}
