// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class Test1 {
  void bar(bool condition) {
    if (condition) {
      Expect.fail('Should not reach here');
    }
    Expect.fail('Should throw earlier');
  }
}

void test1(bool condition) {
  Test1 obj = new Test1();
  obj.bar(condition);
}

class Test2 {
  bool condition;
  Test2(this.condition);

  void bar() {
    if (!condition) {
      Expect.fail('Should not reach here');
    }
    Expect.fail('Should throw earlier');
  }
}

void test2(bool condition) {
  Test2 obj = new Test2(condition);
  obj.bar();
}

class Test3 {
  bool condition;
  Test3(this.condition);

  bool bazz() => condition;

  void bar() {
    while (bazz() || bazz()) {
      Expect.fail('Should not reach here');
    }
    Expect.fail('Should throw earlier');
  }
}

void test3(bool condition) {
  Test3 obj = new Test3(condition);
  obj.bar();
}

const bool test4Condition = null;

void test4(bool condition) {
  if (test4Condition) {
    Expect.fail('Should not reach here');
  }
  Expect.fail('Should throw earlier');
}

void test5(bool condition) {
  if (null) {
    Expect.fail('Should not reach here');
  }
  Expect.fail('Should throw earlier');
}

void testStackTrace(void testCase(bool condition), List<int> lineNumbers) {
  try {
    testCase(null);
    Expect.fail("Using null in a bool condition should throw TypeError");
  } catch (e, stacktrace) {
    print('--------- exception ---------');
    print(e);
    print('-------- stack trace --------');
    print(stacktrace);
    print('-----------------------------');

    Expect.isTrue(e is AssertionError);
    Expect.equals(
        'Failed assertion: boolean expression must not be null', e.toString());

    final String st = stacktrace.toString();
    for (int lineNum in lineNumbers) {
      String item = '.dart:$lineNum';
      Expect.isTrue(st.contains(item), "Stack trace doesn't contain $item");
    }
    print('OK');
  }
}

main() {
  testStackTrace(test1, [9, 18]);
  testStackTrace(test2, [26, 35]);
  testStackTrace(test3, [45, 54]);
  testStackTrace(test4, [60]); //# 01: ok
  testStackTrace(test5, [67]); //# 02: ok
}
