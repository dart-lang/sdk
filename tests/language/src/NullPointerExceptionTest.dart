// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class NullPointerExceptionTest {

  static void testNullPointerExceptionVariable() {
    int variable;
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;
    try {
      variable++;
    } catch (NullPointerException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
  }

  static int helperFunction(int parameter) {
    return parameter++;
  }

  static void testNullPointerExceptionFunctionCall() {
    int variable;
    bool exceptionCaught = false;
    bool wrongExceptionCaught = false;
    try {
      variable = helperFunction(variable);
    } catch (NullPointerException ex) {
      exceptionCaught = true;
    } catch (Exception ex) {
      wrongExceptionCaught = true;
    }
    Expect.equals(true, exceptionCaught);
    Expect.equals(true, !wrongExceptionCaught);
  }

  static void testMain() {
    testNullPointerExceptionVariable();
    testNullPointerExceptionFunctionCall();
  }
}

main() {
  NullPointerExceptionTest.testMain();
}
