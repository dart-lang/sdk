// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests of literals (and imports, return, ==, and static methods).
import 'package:expect/expect.dart';

test0() {
  return 'Hello, world!';
}

test1() {
  return 42;
}

test2() {
  return 2.71828;
}

test3() {
  return 6.022e23;
}

test4() {
  return true;
}

test5() {
  return false;
}

test6() {
  return 1405006117752879898543142606244511569936384000000000;
}

main() {
  Expect.isTrue(test0() == 'Hello, world!');
  Expect.isTrue(test1() == 42);
  Expect.isTrue(test2() == 2.71828);
  Expect.isTrue(test3() == 6.022e23);
  Expect.isTrue(test4());
  Expect.isTrue(test5() == false);
  Expect
      .isTrue(test6() == 1405006117752879898543142606244511569936384000000000);
}
