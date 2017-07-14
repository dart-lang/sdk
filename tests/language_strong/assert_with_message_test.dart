// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

main() {
  var assertsEnabled = false;
  assert((assertsEnabled = true));
  if (!assertsEnabled) return;

  // TODO(rnystrom): Test cases where the first argument to assert() is a
  // function.

  testAssertFails();
  testAssertDoesNotFail();
  testNullMessage();
  testDoesNotEvaluateMessageIfAssertSucceeds();
  testMessageExpressionThatThrows();
  testCallsToStringOnMessageLazily();
}

/// A class with a custom toString() that tracks when it is called.
class ToString {
  bool calledToString = false;

  String toString() {
    calledToString = true;
    return "toString!";
  }
}

testAssertFails() {
  try {
    assert(false, "Oops");
    Expect.fail("Assert should throw.");
  } catch (e) {
    Expect.isTrue(e.toString().contains("Oops"));
  }
}

testAssertDoesNotFail() {
  try {
    assert(true, "Oops");
  } catch (e) {
    Expect.fail("Assert should not throw.");
  }
}

testNullMessage() {
  try {
    assert(false, null);
    Expect.fail("Assert should throw.");
  } catch (e) {
    Expect.isTrue(e.toString().contains("is not true"));
  }
}

testDoesNotEvaluateMessageIfAssertSucceeds() {
  try {
    var evaluated = false;
    assert(true, evaluated = true);
    Expect.isFalse(evaluated);
  } catch (e) {
    Expect.fail("Assert should not throw.");
  }
}

testMessageExpressionThatThrows() {
  try {
    assert(false, throw "dang");
    Expect.fail("Should throw");
  } catch (e) {
    Expect.equals(e, "dang");
  }
}

testCallsToStringOnMessageLazily() {
  var toString = new ToString();
  try {
    assert(false, toString);
    Expect.fail("Assert should throw.");
  } catch (e) {
    Expect.isFalse(toString.calledToString);
    Expect.isTrue(e.toString().contains("Instance of 'ToString'"));
    Expect.isFalse(toString.calledToString);
  }
}
