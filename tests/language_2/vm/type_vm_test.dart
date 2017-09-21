// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks --enable_asserts --no_show_internal_names
// Dart test program testing type checks.

import "package:expect/expect.dart";

class C {
  factory C() {
    return 1; //# 01: compile-time error
  }
}

class TypeTest {
  static test() {
    int i = "hello"; //# 02: compile-time error
    return 1;
  }

  static testSideEffect() {
    int result = 0;
    int index() {
      result++;
      return 0;
    }

    try {
      List<int> a = new List<int>(1);
      a[0] = 0;
      a[index()]++; // Type check succeeds, but does not create side effects.
      Expect.equals(1, a[0]);
    } on TypeError catch (error) {
      result = 100;
    }
    return result;
  }

  static testArgument() {
    int f(int i) {
      return i;
    }
    int i = f("hello"); //# 03: compile-time error
    return 1;
  }

  static testReturn() {
    int f(String s) { //# 04: continued
      return s; //# 04: compile-time error
    } //# 04: continued

    int i = f("hello"); //# 04: continued
    return 1;
  }

  static int field;
  static testField() {
    field = "hello"; //# 05: compile-time error
    return 1;
  }

  static testAnyFunction() {
    Function anyFunction;
    f() {}
    anyFunction = f; // No error.
    int i = f; //# 06: compile-time error
    return 1;
  }

  static testVoidFunction() {
    Function anyFunction;
    void acceptVoidFunObj(void voidFunObj(Object obj)) {}
    void acceptObjFunObj(Object objFunObj(Object obj)) {}
    void voidFunObj(Object obj) {}
    Object objFunObj(Object obj) {
      return obj;
    }

    ;
    anyFunction = voidFunObj; // No error.
    anyFunction = objFunObj; // No error.
    acceptVoidFunObj(voidFunObj);
    acceptVoidFunObj(objFunObj);
    acceptObjFunObj(objFunObj);
    acceptObjFunObj(voidFunObj);
    return 1;
  }

  static testFunctionNum() {
    Function anyFunction;
    void acceptFunNum(void funNum(num n)) {}
    void funObj(Object obj) {}
    void funNum(num n) {}
    void funInt(int i) {}
    void funString(String s) {}
    anyFunction = funObj; // No error.
    anyFunction = funNum; // No error.
    anyFunction = funInt; // No error.
    anyFunction = funString; // No error.
    acceptFunNum(funObj); // No error.
    acceptFunNum(funNum); // No error.
    acceptFunNum(funInt); //# 27: compile-time error
    acceptFunNum(funString); //# 08: compile-time error
    return 1;
  }

  static testBoolCheck() {
      bool i = !"hello"; //# 09: compile-time error
      while ("hello") {} //# 10: compile-time error
      do {} while ("hello"); //# 11: compile-time error
      for (; "hello";) {} //# 12: compile-time error
      int i = "hello" ? 1 : 0; //# 13: compile-time error
      if ("hello") {} //# 14: compile-time error
      if ("hello" || false) {} //# 15: compile-time error
      if (false || "hello") {} //# 16: compile-time error
      if (null) {}
    return 9;
  }

  static int testFactory() {
    var x = new C(); //# 01: continued
    return 1;
  }

  static int testListAssigment() {
    int result = 0;
    {
      var a = new List(5);
      List a0 = a;
      List<Object> ao = a;
      List<int> ai = a;
      List<num> an = a;
      List<String> as = a;
    }
    {
      var a = new List<Object>(5);
      List a0 = a;
      List<Object> ao = a;
      List<int> ai = a;
      List<num> an = a;
      List<String> as = a;
    }
    {
      var a = new List<int>(5);
      List a0 = a;
      List<Object> ao = a;
      List<int> ai = a;
      List<num> an = a;
      List<String> as = a; //# 22: compile-time error
    }
    {
      var a = new List<num>(5);
      List a0 = a;
      List<Object> ao = a;
      List<int> ai = a;
      List<num> an = a;
      List<String> as = a; //# 24: compile-time error
    }
    {
      var a = new List<String>(5);
      List a0 = a;
      List<Object> ao = a;
      List<int> ai = a; //# 25: compile-time error
      List<num> an = a; //# 26: compile-time error
      List<String> as = a;
    }
    return 8;
  }

  static testMain() {
    Expect.equals(1, test());
    Expect.equals(1, testSideEffect());
    Expect.equals(1, testArgument());
    Expect.equals(1, testReturn());
    Expect.equals(1, testField());
    Expect.equals(1, testAnyFunction());
    Expect.equals(1, testVoidFunction());
    Expect.equals(1, testFunctionNum());
    Expect.equals(9, testBoolCheck());
    Expect.equals(1, testFactory());
    Expect.equals(8, testListAssigment());
  }
}

main() {
  TypeTest.testMain();
}
