// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--enable_type_checks --enable_asserts --no_show_internal_names
// Dart test program testing type checks.

import "package:expect/expect.dart";

class C {
  factory C() {
    return 1;  // Implicit result type is 'C', not int.
  }
}

class TypeTest {
  static test() {
    int result = 0;
    try {
      int i = "hello";  // Throws a TypeError if type checks are enabled.
    } on TypeError catch (error) {
      result = 1;
      var msg = error.toString();
      Expect.isTrue(msg.contains("'int'"));  // dstType
      Expect.isTrue(msg.contains("'String'"));  // srcType
      Expect.isTrue(msg.contains("'i'"));  // dstName
      Expect.isTrue(error.stackTrace.toString().contains(
          "type_vm_test.dart:19:15"));
    }
    return result;
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
      a[index()]++;  // Type check succeeds, but does not create side effects.
      Expect.equals(1, a[0]);
    } on TypeError catch (error) {
      result = 100;
    }
    return result;
  }

  static testArgument() {
    int result = 0;
    int f(int i) {
      return i;
    }
    try {
      int i = f("hello");  // Throws a TypeError if type checks are enabled.
    } on TypeError catch (error) {
      result = 1;
      var msg = error.toString();
      Expect.isTrue(msg.contains("'int'"));  // dstType
      Expect.isTrue(msg.contains("'String'"));  // srcType
      Expect.isTrue(msg.contains("'i'"));  // dstName
      Expect.isTrue(error.stackTrace.toString().contains(
          "type_vm_test.dart:51:15"));
    }
    return result;
  }

  static testReturn() {
    int result = 0;
    int f(String s) {
      return s;
    }
    try {
      int i = f("hello");  // Throws a TypeError if type checks are enabled.
    } on TypeError catch (error) {
      result = 1;
      var msg = error.toString();
      Expect.isTrue(msg.contains("'int'"));  // dstType
      Expect.isTrue(msg.contains("'String'"));  // srcType
      Expect.isTrue(msg.contains("function result"));  // dstName
      Expect.isTrue(error.stackTrace.toString().contains(
          "type_vm_test.dart:71:14"));
    }
    return result;
  }

  static int field;
  static testField() {
    int result = 0;
    try {
      field = "hello";  // Throws a TypeError if type checks are enabled.
    } on TypeError catch (error) {
      result = 1;
      var msg = error.toString();
      Expect.isTrue(msg.contains("'int'"));  // dstType
      Expect.isTrue(msg.contains("'String'"));  // srcType
      Expect.isTrue(msg.contains("'field'"));  // dstName
      Expect.isTrue(error.stackTrace.toString().contains(
          "type_vm_test.dart:91:15"));
    }
    return result;
  }

  static testAnyFunction() {
    int result = 0;
    Function anyFunction;
    f() { };
    anyFunction = f;  // No error.
    try {
      int i = f;  // Throws a TypeError if type checks are enabled.
    } on TypeError catch (error) {
      result = 1;
      var msg = error.toString();
      Expect.isTrue(msg.contains("'int'"));  // dstType
      Expect.isTrue(msg.contains("'() => dynamic'"));  // srcType
      Expect.isTrue(msg.contains("'i'"));  // dstName
      Expect.isTrue(error.stackTrace.toString().contains(
          "type_vm_test.dart:110:15"));
    }
    return result;
  }

  static testVoidFunction() {
    int result = 0;
    Function anyFunction;
    void acceptVoidFunObj(void voidFunObj(Object obj)) { };
    void acceptObjFunObj(Object objFunObj(Object obj)) { };
    void voidFunObj(Object obj) { };
    Object objFunObj(Object obj) { return obj; };
    anyFunction = voidFunObj;  // No error.
    anyFunction = objFunObj;  // No error.
    acceptVoidFunObj(voidFunObj);
    acceptVoidFunObj(objFunObj);
    acceptObjFunObj(objFunObj);
    try {
      acceptObjFunObj(voidFunObj);  // Throws a TypeError.
    } on TypeError catch (error) {
      result = 1;
      var msg = error.toString();
      Expect.isTrue(msg.contains("'(Object) => Object'"));  // dstType
      Expect.isTrue(msg.contains("'(Object) => void'"));  // srcType
      Expect.isTrue(msg.contains("'objFunObj'"));  // dstName
      Expect.isTrue(error.stackTrace.toString().contains(
          "type_vm_test.dart:127:33"));
    }
    return result;
  }

  static testFunctionNum() {
    int result = 0;
    Function anyFunction;
    void acceptFunNum(void funNum(num n)) { };
    void funObj(Object obj) { };
    void funNum(num n) { };
    void funInt(int i) { };
    void funString(String s) { };
    anyFunction = funObj;  // No error.
    anyFunction = funNum;  // No error.
    anyFunction = funInt;  // No error.
    anyFunction = funString;  // No error.
    acceptFunNum(funObj);  // No error.
    acceptFunNum(funNum);  // No error.
    acceptFunNum(funInt);  // No error.
    try {
      acceptFunNum(funString);  // Throws an error.
    } on TypeError catch (error) {
      result = 1;
      var msg = error.toString();
      Expect.isTrue(msg.contains("'(num) => void'"));  // dstType
      Expect.isTrue(msg.contains("'(String) => void'"));  // srcType
      Expect.isTrue(msg.contains("'funNum'"));  // dstName
      Expect.isTrue(error.stackTrace.toString().contains(
          "type_vm_test.dart:152:28"));
    }
    return result;
  }

  static testBoolCheck() {
    int result = 0;
    try {
      bool i = !"hello";  // Throws a TypeError if type checks are enabled.
    } on TypeError catch (error) {
      result++;
      var msg = error.toString();
      Expect.isTrue(msg.contains("'bool'"));  // dstType
      Expect.isTrue(msg.contains("'String'"));  // srcType
      Expect.isTrue(msg.contains("boolean expression"));  // dstName
      Expect.isTrue(error.stackTrace.toString().contains(
          "type_vm_test.dart:181:17"));
    }
    try {
      while ("hello") {};  // Throws a TypeError if type checks are enabled.
    } on TypeError catch (error) {
      result++;
      var msg = error.toString();
      Expect.isTrue(msg.contains("'bool'"));  // dstType
      Expect.isTrue(msg.contains("'String'"));  // srcType
      Expect.isTrue(msg.contains("boolean expression"));  // dstName
      Expect.isTrue(error.stackTrace.toString().contains(
          "type_vm_test.dart:192:14"));
    }
    try {
      do {} while ("hello");  // Throws a TypeError if type checks are enabled.
    } on TypeError catch (error) {
      result++;
      var msg = error.toString();
      Expect.isTrue(msg.contains("'bool'"));  // dstType
      Expect.isTrue(msg.contains("'String'"));  // srcType
      Expect.isTrue(msg.contains("boolean expression"));  // dstName
      Expect.isTrue(error.stackTrace.toString().contains(
          "type_vm_test.dart:203:20"));
    }
    try {
      for (;"hello";) {};  // Throws a TypeError if type checks are enabled.
    } on TypeError catch (error) {
      result++;
      var msg = error.toString();
      Expect.isTrue(msg.contains("'bool'"));  // dstType
      Expect.isTrue(msg.contains("'String'"));  // srcType
      Expect.isTrue(msg.contains("boolean expression"));  // dstName
      Expect.isTrue(error.stackTrace.toString().contains(
          "type_vm_test.dart:214:13"));
    }
    try {
      int i = "hello" ? 1 : 0;  // Throws a TypeError if type checks are enabled.
    } on TypeError catch (error) {
      result++;
      var msg = error.toString();
      Expect.isTrue(msg.contains("'bool'"));  // dstType
      Expect.isTrue(msg.contains("'String'"));  // srcType
      Expect.isTrue(msg.contains("boolean expression"));  // dstName
      Expect.isTrue(error.stackTrace.toString().contains(
          "type_vm_test.dart:225:15"));
    }
    try {
      if ("hello") {};  // Throws a TypeError if type checks are enabled.
    } on TypeError catch (error) {
      result++;
      var msg = error.toString();
      Expect.isTrue(msg.contains("'bool'"));  // dstType
      Expect.isTrue(msg.contains("'String'"));  // srcType
      Expect.isTrue(msg.contains("boolean expression"));  // dstName
      Expect.isTrue(error.stackTrace.toString().contains(
          "type_vm_test.dart:236:11"));
    }
    try {
      if ("hello" || false) {};  // Throws a TypeError if type checks are enabled.
    } on TypeError catch (error) {
      result++;
      var msg = error.toString();
      Expect.isTrue(msg.contains("'bool'"));  // dstType
      Expect.isTrue(msg.contains("'String'"));  // srcType
      Expect.isTrue(msg.contains("boolean expression"));  // dstName
      Expect.isTrue(error.stackTrace.toString().contains(
          "type_vm_test.dart:247:11"));
    }
    try {
      if (false || "hello") {};  // Throws a TypeError if type checks are enabled.
    } on TypeError catch (error) {
      result++;
      var msg = error.toString();
      Expect.isTrue(msg.contains("'bool'"));  // dstType
      Expect.isTrue(msg.contains("'String'"));  // srcType
      Expect.isTrue(msg.contains("boolean expression"));  // dstName
      Expect.isTrue(error.stackTrace.toString().contains(
          "type_vm_test.dart:258:20"));
    }
    try {
      if (null) {};  // Throws an AssertionError if assertions are enabled.
    } on AssertionError catch (error) {
      result++;
      var msg = error.toString();
      Expect.isTrue(msg.contains("assertion"));
      Expect.isTrue(msg.contains("boolean expression"));
      Expect.isTrue(msg.contains("null"));
    }
    return result;
  }


  static int testFactory() {
    int result = 0;
    try {
      var x = new C();
    } on TypeError catch (error) {
      result++;
      var msg = error.toString();
      Expect.isTrue(msg.contains("'C'"));  // dstType
      Expect.isTrue(msg.contains("'int'"));  // srcType
      Expect.isTrue(msg.contains("function result"));  // dstName
      Expect.isTrue(error.stackTrace.toString().contains(
          "type_vm_test.dart:11:12"));
    }
    return result;
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
      try {
        List<int> ai = a;
      } on TypeError catch (error) {
        result++;
        var msg = error.toString();
        Expect.isTrue(msg.contains("'List<int>'"));  // dstType
        Expect.isTrue(msg.contains("'List<Object>'"));  // srcType
        Expect.isTrue(msg.contains("'ai'"));  // dstName
        Expect.isTrue(error.stackTrace.toString().contains(
            "type_vm_test.dart:312:24"));
      }
      try {
        List<num> an = a;
      } on TypeError catch (error) {
        result++;
        var msg = error.toString();
        Expect.isTrue(msg.contains("'List<num>'"));  // dstType
        Expect.isTrue(msg.contains("'List<Object>'"));  // srcType
        Expect.isTrue(msg.contains("'an'"));  // dstName
        Expect.isTrue(error.stackTrace.toString().contains(
            "type_vm_test.dart:323:24"));
      }
      try {
        List<String> as = a;
      } on TypeError catch (error) {
        result++;
        var msg = error.toString();
        Expect.isTrue(msg.contains("'List<String>'"));  // dstType
        Expect.isTrue(msg.contains("'List<Object>'"));  // srcType
        Expect.isTrue(msg.contains("'as'"));  // dstName
        Expect.isTrue(error.stackTrace.toString().contains(
            "type_vm_test.dart:334:27"));
      }
    }
    {
      var a = new List<int>(5);
      List a0 = a;
      List<Object> ao = a;
      List<int> ai = a;
      List<num> an = a;
      try {
        List<String> as = a;
      } on TypeError catch (error) {
        result++;
        var msg = error.toString();
        Expect.isTrue(msg.contains("'List<String>'"));  // dstType
        Expect.isTrue(msg.contains("'List<int>'"));  // srcType
        Expect.isTrue(msg.contains("'as'"));  // dstName
        Expect.isTrue(error.stackTrace.toString().contains(
            "type_vm_test.dart:352:27"));
      }
    }
    {
      var a = new List<num>(5);
      List a0 = a;
      List<Object> ao = a;
      try {
        List<int> ai = a;
      } on TypeError catch (error) {
        result++;
        var msg = error.toString();
        Expect.isTrue(msg.contains("'List<int>'"));  // dstType
        Expect.isTrue(msg.contains("'List<num>'"));  // srcType
        Expect.isTrue(msg.contains("'ai'"));  // dstName
        Expect.isTrue(error.stackTrace.toString().contains(
            "type_vm_test.dart:368:24"));
      }
      List<num> an = a;
      try {
        List<String> as = a;
      } on TypeError catch (error) {
        result++;
        var msg = error.toString();
        Expect.isTrue(msg.contains("'List<String>'"));  // dstType
        Expect.isTrue(msg.contains("'List<num>'"));  // srcType
        Expect.isTrue(msg.contains("'as'"));  // dstName
        Expect.isTrue(error.stackTrace.toString().contains(
            "type_vm_test.dart:380:27"));
      }
    }
    {
      var a = new List<String>(5);
      List a0 = a;
      List<Object> ao = a;
      try {
        List<int> ai = a;
      } on TypeError catch (error) {
        result++;
        var msg = error.toString();
        Expect.isTrue(msg.contains("'List<int>'"));  // dstType
        Expect.isTrue(msg.contains("'List<String>'"));  // srcType
        Expect.isTrue(msg.contains("'ai'"));  // dstName
        Expect.isTrue(error.stackTrace.toString().contains(
            "type_vm_test.dart:396:24"));
      }
      try {
        List<num> an = a;
      } on TypeError catch (error) {
        result++;
        var msg = error.toString();
        Expect.isTrue(msg.contains("'List<num>'"));  // dstType
        Expect.isTrue(msg.contains("'List<String>'"));  // srcType
        Expect.isTrue(msg.contains("'an'"));  // dstName
        Expect.isTrue(error.stackTrace.toString().contains(
            "type_vm_test.dart:407:24"));
      }
      List<String> as = a;
    }
    return result;
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
