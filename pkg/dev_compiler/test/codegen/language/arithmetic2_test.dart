// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// Dart test program to test arithmetic operations.

import "package:expect/expect.dart";

class A {
  static foo() => 499;
}

bool throwsNoSuchMethod(f) {
  try {
    f();
    return false;
  } on NoSuchMethodError catch (e) {
    return true;
  }
  return false;
}

bool throwsBecauseOfBadArgument(f) {
  try {
    f();
    return false;
  } on NoSuchMethodError catch (e) {
    return true;
  } on ArgumentError catch (e) {
    return true;
  } on TypeError catch (e) {
    // In type checked mode.
    return true;
  }
  return false;
}

numberOpBadSecondArgument(f) {
  Expect.isTrue(throwsBecauseOfBadArgument(() => f(true)));
  Expect.isTrue(throwsBecauseOfBadArgument(() => f(new A())));
  Expect.isTrue(throwsBecauseOfBadArgument(() => f("foo")));
  Expect.isTrue(throwsBecauseOfBadArgument(() => f("5")));
  Expect.isTrue(throwsBecauseOfBadArgument(() => f(() => 499)));
  Expect.isTrue(throwsBecauseOfBadArgument(() => f(null)));
  Expect.isTrue(throwsBecauseOfBadArgument(() => f(false)));
  Expect.isTrue(throwsBecauseOfBadArgument(() => f([])));
  Expect.isTrue(throwsBecauseOfBadArgument(() => f({})));
  Expect.isTrue(throwsBecauseOfBadArgument(() => f(A.foo)));
}

badOperations(b) {
  Expect.isTrue(throwsNoSuchMethod(() => b - 3));
  Expect.isTrue(throwsNoSuchMethod(() => b * 3));
  Expect.isTrue(throwsNoSuchMethod(() => b ~/ 3));
  Expect.isTrue(throwsNoSuchMethod(() => b / 3));
  Expect.isTrue(throwsNoSuchMethod(() => b % 3));
  Expect.isTrue(throwsNoSuchMethod(() => b + 3));
  Expect.isTrue(throwsNoSuchMethod(() => b[3]));
  Expect.isTrue(throwsNoSuchMethod(() => ~b));
  Expect.isTrue(throwsNoSuchMethod(() => -b));
}

main() {
  numberOpBadSecondArgument((x) => 3 + x);
  numberOpBadSecondArgument((x) => 3 - x);
  numberOpBadSecondArgument((x) => 3 * x);
  numberOpBadSecondArgument((x) => 3 / x);
  numberOpBadSecondArgument((x) => 3 ~/ x);
  numberOpBadSecondArgument((x) => 3 % x);
  badOperations(true);
  badOperations(false);
  badOperations(() => 499);
  badOperations(A.foo);
}
