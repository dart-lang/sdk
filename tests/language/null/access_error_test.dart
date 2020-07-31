// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class NullAccessTest {
  static void testNullVariable() {
    dynamic variable;
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;
    try {
      variable++;
    } on NoSuchMethodError catch (ex) {
      exceptionCaught = true;
    } catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.isTrue(exceptionCaught);
    Expect.isFalse(wrongExceptionCaught);
  }

  static dynamic helperFunction(dynamic parameter) {
    return parameter++;
  }

  static void testNullFunctionCall() {
    dynamic variable;
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;
    try {
      variable = helperFunction(variable);
    } on NoSuchMethodError catch (ex) {
      exceptionCaught = true;
    } catch (ex) {
      wrongExceptionCaught = true;
    }
    Expect.isTrue(exceptionCaught);
    Expect.isFalse(wrongExceptionCaught);
  }

  static void testMain() {
    testNullVariable();
    testNullFunctionCall();
  }
}

main() {
  NullAccessTest.testMain();
}
