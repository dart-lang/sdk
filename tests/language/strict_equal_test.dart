// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.


main() {
  for (int i = 0; i < 6000; i++) {
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
  }
}


test1(a) {
  return a === 3;
}

test2(a) {
  return a !== 3;
}


test2r(a) {
  return 3 !== a;
}


test3() {
  return get5() === 5;
}


test4(a) {
  if (a === 3) {
    return 1;
  } else {
    return 2;
  }
}


test5(a) {
  if (a !== 3) {
    return 1;
  } else {
    return 2;
  }
}


test6() {
  if (get5() === 5) {
    return 1;
  } else {
    return 2;
  }
}

get5() {
  return 5;
}

test7() {
  return null !== null;
}


test8() {
  if (null !== null) {
    return 1;
  } else {
    return 2;
  }
}
