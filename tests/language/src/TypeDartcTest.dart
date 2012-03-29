// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program testing type checks.

class TypeTest {
  static test() {
    int result = 0;
    try {
      // Throws a TypeError if type checks are enabled.
      int i = "hello";   /// static type warning
    } catch (TypeError error) {
      result = 1;
      Expect.equals("int", error.dstType);
      Expect.equals("String", error.srcType);
      Expect.equals("i", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("TypeTest.dart", subs);
      Expect.equals(12, error.line);
      Expect.equals(15, error.column);
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
      assert(a[0] == 1);
    } catch (TypeError error) {
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
      // Throws a TypeError if type checks are enabled.
      int i = f("hello");  /// static type warning
    } catch (TypeError error) {
      result = 1;
      Expect.equals("int", error.dstType);
      Expect.equals("String", error.srcType);
      Expect.equals("i", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("TypeTest.dart", subs);
      Expect.equals(49, error.line);
      Expect.equals(15, error.column);
    }
    return result;
  }

  static testReturn() {
    int result = 0;
    int f(String s) {
      // String not assignable to int on return
      return s;  /// static type warning
    }
    try {
      // Throws a TypeError if type checks are enabled. 
      int i = f("hello"); 
    } catch (TypeError error) {
      result = 1;
      Expect.equals("int", error.dstType);
      Expect.equals("String", error.srcType);
      Expect.equals("function result", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("TypeTest.dart", subs);
      Expect.equals(74, error.line);
      Expect.equals(14, error.column);
    }
    return result;
  }

  static int field;
  static testField() {
    int result = 0;
    try {
      // Throws a TypeError if type checks are enabled.
      field = "hello";  /// static type warning 
    } catch (TypeError error) {
      result = 1;
      Expect.equals("int", error.dstType);
      Expect.equals("String", error.srcType);
      Expect.equals("field", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("TypeTest.dart", subs);
      Expect.equals(99, error.line);
      Expect.equals(15, error.column);
    }
    return result;
  }

  static testAnyFunction() {
    int result = 0;
    Function anyFunction;
    f() { };
    anyFunction = f;  // No error.
    try {
      // Throws a TypeError if type checks are enabled.
      int i = f;  /// static type warning
    } catch (TypeError error) {
      result = 1;
      Expect.equals("int", error.dstType);
      Expect.equals("() => var", error.srcType);  // TODO(regis): => Dynamic.
      Expect.equals("i", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("TypeTest.dart", subs);
      Expect.equals(123, error.line);
      Expect.equals(15, error.column);
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
      // Throws a TypeError.  Issue 2348
      acceptObjFunObj(voidFunObj);   /// static type warning
    } catch (TypeError error) {
      result = 1;
      Expect.equals("(Object) => Object", error.dstType);
      Expect.equals("(Object) => void", error.srcType);
      Expect.equals("objFunObj", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("TypeTest.dart", subs);
      Expect.equals(145, error.line);
      Expect.equals(33, error.column);
    }
    return result;
  }

  static testFunctionNum() {
    int result = 0;
    Function anyFunction;
    void acceptFunNum(void funNum(num num)) { };
    void funObj(Object obj) { };
    void funNum(num num) { };
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
      // Throws an error.
      acceptFunNum(funString);   /// static type warning
    } catch (TypeError error) {
      result = 1;
      Expect.equals("(num) => void", error.dstType);
      Expect.equals("(String) => void", error.srcType);
      Expect.equals("funNum", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("TypeTest.dart", subs);
      Expect.equals(175, error.line);
      Expect.equals(28, error.column);
    }
    return result;
  }

  static testBoolCheck() {
    int result = 0;
    try {
      // Throws a TypeError if type checks are enabled.
      bool i = !"hello";   /// static type warning
    } catch (TypeError error) {
      result++;
      Expect.equals("bool", error.dstType);
      Expect.equals("String", error.srcType);
      Expect.equals("boolean expression", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("TypeTest.dart", subs);
      Expect.equals(209, error.line);
      Expect.equals(17, error.column);
    }
    try {
      // Throws a TypeError if type checks are enabled.
      while ("hello") {};   /// static type warning
    } catch (TypeError error) {
      result++;
      Expect.equals("bool", error.dstType);
      Expect.equals("String", error.srcType);
      Expect.equals("boolean expression", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("TypeTest.dart", subs);
      Expect.equals(225, error.line);
      Expect.equals(14, error.column);
    }
    try {
      // Throws a TypeError if type checks are enabled.
      do {} while ("hello");   /// static type warning
    } catch (TypeError error) {
      result++;
      Expect.equals("bool", error.dstType);
      Expect.equals("String", error.srcType);
      Expect.equals("boolean expression", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("TypeTest.dart", subs);
      Expect.equals(241, error.line);
      Expect.equals(20, error.column);
    }
    try {
      // Throws a TypeError if type checks are enabled.
      for (;"hello";) {};   /// static type warning
    } catch (TypeError error) {
      result++;
      Expect.equals("bool", error.dstType);
      Expect.equals("String", error.srcType);
      Expect.equals("boolean expression", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("TypeTest.dart", subs);
      Expect.equals(257, error.line);
      Expect.equals(13, error.column);
    }
    try {
      // Throws a TypeError if type checks are enabled.
      int i = "hello" ? 1 : 0;   /// static type warning
    } catch (TypeError error) {
      result++;
      Expect.equals("bool", error.dstType);
      Expect.equals("String", error.srcType);
      Expect.equals("boolean expression", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("TypeTest.dart", subs);
      Expect.equals(273, error.line);
      Expect.equals(15, error.column);
    }
    try {
      // Throws a TypeError if type checks are enabled.
      if ("hello") {};   /// static type warning
    } catch (TypeError error) {
      result++;
      Expect.equals("bool", error.dstType);
      Expect.equals("String", error.srcType);
      Expect.equals("boolean expression", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("TypeTest.dart", subs);
      Expect.equals(289, error.line);
      Expect.equals(11, error.column);
    }
    try {
      // Throws a TypeError if type checks are enabled.
      if ("hello" || false) {};  /// static type warning
    } catch (TypeError error) {
      result++;
      Expect.equals("bool", error.dstType);
      Expect.equals("String", error.srcType);
      Expect.equals("boolean expression", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("TypeTest.dart", subs);
      Expect.equals(305, error.line);
      Expect.equals(11, error.column);
    }
    try {
      // Throws a TypeError if type checks are enabled.
      if (false || "hello") {};  /// static type warning
    } catch (TypeError error) {
      result++;
      Expect.equals("bool", error.dstType);
      Expect.equals("String", error.srcType);
      Expect.equals("boolean expression", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("TypeTest.dart", subs);
      Expect.equals(321, error.line);
      Expect.equals(20, error.column);
    }
    try {
      // TODO: I don't this should throw a TypeError, as null is a valid bool
      // value.  It might well should throw some other exception however.
      // if (null) {};  // Throws a TypeError if type checks are enabled.
    } catch (TypeError error) {
      result++;
      Expect.equals("bool", error.dstType);
      Expect.equals("Null", error.srcType);
      Expect.equals("boolean expression", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("TypeTest.dart", subs);
      Expect.equals(337, error.line);
      Expect.equals(11, error.column);
    }
    return result;
  }


  static int testFactory() {
    int result = 0;
    try {
      var x = new C();
    } catch (TypeError error) {
      result++;
      Expect.equals("C", error.dstType);
      Expect.equals("Smi", error.srcType);
      Expect.equals("function result", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("TypeTest.dart", subs);
      Expect.equals(472, error.line);
      Expect.equals(12, error.column);
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
      } catch (TypeError error) {
        result++;
      }
      try {
        List<num> an = a;
      } catch (TypeError error) {
        result++;
      }
      try {
        List<String> as = a;
      } catch (TypeError error) {
        result++;
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
      } catch (TypeError error) {
        result++;
      }
    }
    {
      var a = new List<num>(5);
      List a0 = a;
      List<Object> ao = a;
      try {
        List<int> ai = a;
      } catch (TypeError error) {
        result++;
      }
      List<num> an = a;
      try {
        List<String> as = a;
      } catch (TypeError error) {
        result++;
      }
    }
    {
      var a = new List<String>(5);
      List a0 = a;
      List<Object> ao = a;
      try {
        List<int> ai = a;
      } catch (TypeError error) {
        result++;
      }
      try {
        List<num> an = a;
      } catch (TypeError error) {
        result++;
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
    //Expect.equals(1, testVoidFunction()); - Function type checking issue
    //Expect.equals(1, testFunctionNum());  - Function type checking issue
    Expect.equals(8, testBoolCheck());
    //Expect.equals(1, testFactory());      - Not doing a test on factories
    Expect.equals(8, testListAssigment());
  }
}


class C {
  factory C() {
    return 1;  // Implicit result type is 'C', not int.
  }
}


main() {
  TypeTest.testMain();
}
