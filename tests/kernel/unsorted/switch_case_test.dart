// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';

mkOne() => 1;
mkTwo() => 2;

testNormal() {
  int result;
  switch (mkOne()) {
    case 0:
      result = 0;
      break;
    case 1:
      result = 1;
      break;
    case 2:
      result = 2;
      break;
    default:
      result = 3;
      break;
  }
  Expect.isTrue(result == 1);
}

testDefault() {
  int result;
  switch (null) {
    case 0:
      result = 0;
      break;
    case 1:
      result = 1;
      break;
    case 2:
      result = 2;
      break;
    default:
      result = 3;
      break;
  }
  Expect.isTrue(result == 3);
}

testFallThrough() {
  int result;
  switch (mkOne()) {
    case 0:
      result = 0;
      break;
    case 1:
    case 2:
      result = 2;
      break;
    default:
      result = 3;
      break;
  }
  Expect.isTrue(result == 2);
}

testContinue() {
  int result;
  switch (mkTwo()) {
    case 0:
      result = 0;
      break;

    setitto1:
    case 1:
      result = 1;
      continue setitto3;

    case 2:
      result = 2;
      continue setitto1;

    setitto3:
    default:
      result = 3;
      break;
  }
  Expect.isTrue(result == 3);
}

testOnlyDefault() {
  int result;
  switch (mkTwo()) {
    default:
      result = 42;
  }
  Expect.isTrue(result == 42);
}

testOnlyDefaultWithBreak() {
  int result;
  switch (mkTwo()) {
    default:
      result = 42;
  }
  Expect.isTrue(result == 42);
}

String testReturn() {
  switch (mkOne()) {
    case 0:
      return "bad";
    case 1:
      return "good";
    default:
      return "bad";
  }
}

regressionTest() {
  Expect.isTrue(regressionTestHelper(0, 0) == -1);
  Expect.isTrue(regressionTestHelper(4, 0) == -1);
  Expect.isTrue(regressionTestHelper(4, 1) == 42);
}

regressionTestHelper(i, j) {
  switch (i) {
    case 4:
      switch (j) {
        case 1:
          return 42;
      }
  }
  return -1;
}

regressionTest2() {
  var state = 1;
  while (state < 2) {
    switch (state) {
      case 1:
        state++;
        break;
      case 3:
      case 4:
        // We will translate this currently to an empty [Fragment] which can
        // cause issues if we would like to append/prepend to it.
        assert(false);
    }
  }
  return [1];
}

regressionTest3() {
  f(x) {
    switch (x) {
      case 1:
        return 2;
      case 2:
    }
    throw new UnsupportedError("Unexpected constant kind.");
  }

  Expect.isTrue(f(1) == 2);
}

main() {
  testNormal();
  testDefault();
  testFallThrough();
  testContinue();
  testOnlyDefault();
  testOnlyDefaultWithBreak();
  regressionTest();
  regressionTest2();
  regressionTest3();

  var result = testReturn();
  Expect.isTrue(result == "good");
}
