// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--optimization-counter-threshold=10 --no-background-compilation

import "package:expect/expect.dart";

main() {
  for (int i = 0; i < 20; i++) {
    Expect.isFalse(test1(5));
    Expect.isTrue(test1(3));

    Expect.isTrue(test2(5));
    Expect.isFalse(test2(3));

    Expect.isTrue(test2r(5));
    Expect.isFalse(test2r(3));

    Expect.isTrue(test3());

    Expect.equals(2, test4(5));
    Expect.equals(1, test4(3));

    Expect.equals(1, test5(5));
    Expect.equals(2, test5(3));

    Expect.equals(1, test6());

    Expect.isFalse(test7());
    Expect.equals(2, test8());

    Expect.isFalse(test9(2));
    Expect.isFalse(test9r(2));
    Expect.isTrue(test9(0));
    Expect.isTrue(test9r(0));

    Expect.isFalse(test10(0));
    Expect.isFalse(test10r(0));
    Expect.isTrue(test10(2));
    Expect.isTrue(test10r(2));

    test11(i);
  }
}

test1(a) {
  return identical(a, 3);
}

test2(a) {
  return !identical(a, 3);
}

test2r(a) {
  return !identical(3, a);
}

test3() {
  return identical(get5(), 5);
}

test4(a) {
  if (identical(a, 3)) {
    return 1;
  } else {
    return 2;
  }
}

test5(a) {
  if (!identical(a, 3)) {
    return 1;
  } else {
    return 2;
  }
}

test6() {
  if (identical(get5(), 5)) {
    return 1;
  } else {
    return 2;
  }
}

get5() {
  return 5;
}

test7() {
  return null != null;
}

test8() {
  if (null != null) {
    return 1;
  } else {
    return 2;
  }
}

test9(a) {
  return identical(a, 0);
}

test9r(a) {
  return identical(0, a);
}

test10(a) {
  return !identical(a, 0);
}

test10r(a) {
  return !identical(0, a);
}

test11(a) {
  if (identical(a, 0)) {
    Expect.isTrue(identical(0, a));
    Expect.isFalse(!identical(a, 0));
    Expect.isFalse(!identical(0, a));
  } else {
    Expect.isFalse(identical(0, a));
    Expect.isTrue(!identical(a, 0));
    Expect.isTrue(!identical(0, a));
  }
}
