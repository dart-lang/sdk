// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--no_show_internal_names
//
// Dart test program testing type casts.

// Test that the initializer expression gets properly skipped.
bool b = "foo" as double;

class TypeTest {
  static test() {
    int result = 0;
    try {
      var i = "hello" as int;  // Throws a CastError
    } on TypeError catch (error) {
      result = 1;
      Expect.isTrue(error is CastError);
      Expect.equals("int", error.dstType);
      Expect.equals("String", error.srcType);
      Expect.equals("type cast", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("type_cast_vm_test.dart", subs);
      Expect.equals(15, error.line);
      Expect.equals(23, error.column);
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
      var a = new List<int>(1) as List<int>;
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
      int i = f("hello" as int);  // Throws a CastError
    } on TypeError catch (error) {
      result = 1;
      Expect.isTrue(error is CastError);
      Expect.equals("int", error.dstType);
      Expect.equals("String", error.srcType);
      Expect.equals("type cast", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("type_cast_vm_test.dart", subs);
      Expect.equals(57, error.line);
      Expect.equals(25, error.column);
    }
    return result;
  }

  static testReturn() {
    int result = 0;
    int f(String s) {
      return s as int;  // Throws a CastError
    }
    try {
      int i = f("hello");
    } on TypeError catch (error) {
      result = 1;
      Expect.isTrue(error is CastError);
      Expect.equals("int", error.dstType);
      Expect.equals("String", error.srcType);
      Expect.equals("type cast", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("type_cast_vm_test.dart", subs);
      Expect.equals(79, error.line);
      Expect.equals(16, error.column);
    }
    return result;
  }

  static var field = "hello";
  static testField() {
    int result = 0;
    Expect.equals(5, (field as String).length);
    try {
      field as int;  // Throws a CastError
    } on TypeError catch (error) {
      result = 1;
      Expect.equals("int", error.dstType);
      Expect.equals("String", error.srcType);
      Expect.equals("type cast", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("type_cast_vm_test.dart", subs);
      Expect.equals(106, error.line);
      Expect.equals(13, error.column);
    }
    return result;
  }

  static testAnyFunction() {
    int result = 0;
    Function anyFunction;
    f() { };
    anyFunction = f as Function;  // No error.
    anyFunction = null as Function;  // No error.
    try {
      var i = f as int;  // Throws a TypeError if type checks are enabled.
    } on TypeError catch (error) {
      result = 1;
      Expect.equals("int", error.dstType);
      Expect.equals("() => Dynamic", error.srcType);
      Expect.equals("type cast", error.dstName);
      int pos = error.url.lastIndexOf("/", error.url.length);
      if (pos == -1) {
        pos = error.url.lastIndexOf("\\", error.url.length);
      }
      String subs = error.url.substring(pos + 1, error.url.length);
      Expect.equals("type_cast_vm_test.dart", subs);
      Expect.equals(131, error.line);
      Expect.equals(17, error.column);
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
  }
}


main() {
  TypeTest.testMain();
}
