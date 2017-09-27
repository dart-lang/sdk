// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  test(new List<int>(5));
  var l = new List<int>();
  l.length = 5;
  test(l);
}

void test(List<int> list) {
  list[0] = 1;
  list[1] = 2;
  list[2] = 3;
  list[3] = 4;
  list[4] = 1;

  Expect.equals(3, list.indexOf(4, 0));
  Expect.equals(0, list.indexOf(1, 0));
  Expect.equals(4, list.lastIndexOf(1, list.length - 1));

  Expect.equals(4, list.indexOf(1, 1));
  Expect.equals(-1, list.lastIndexOf(4, 2));

  Expect.equals(3, list.indexOf(4, 2));
  Expect.equals(3, list.indexOf(4, -5));
  Expect.equals(-1, list.indexOf(4, 50));

  Expect.equals(-1, list.lastIndexOf(4, 2));
  Expect.equals(-1, list.lastIndexOf(4, -5));
  Expect.equals(3, list.lastIndexOf(4, 50));
}
