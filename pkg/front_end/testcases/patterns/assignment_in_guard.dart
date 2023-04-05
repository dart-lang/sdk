// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

void test1() {
  switch (42) {
    case var v when (v = 1) > 0:
      print(v);
      break;
    default:
  }
}

void test2() {
  var z = switch (42) { int v when (v = 1) >= 0 => v, _ => -1 };
  print(z);
}

void test3() {
  if (42 case var v when (v = 1) > 0) {
    print(v);
  }
}

void test4() {
  List l = [1, if (42 case int v when (v = 1) > 0) v else 1, 3];
  print(l);
}

void test5(o) {
  if (o case [var a]
      when switch (a) {
        5 when (a = 4) < 1 => true,
        _ => false,
      }) {
    print(a);
  }
}
