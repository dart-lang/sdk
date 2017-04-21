// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of return (and imports, literals, ==, and static methods).

import 'package:expect/expect.dart';

test0() {}

test1() {
  return;
}

test3() {
  return 3;
}

test4() => 4;

test5() {
  return 5;
  Expect.isTrue(false);
}

main() {
  Expect.isTrue(test0() == null);
  Expect.isTrue(test1() == null);
  Expect.isTrue(test3() == 3);
  Expect.isTrue(test4() == 4);
  Expect.isTrue(test5() == 5);
}
