// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Tests classes with getters and setters that do not have the same type.

class A {
  int a() {
    return 37;
  }
}

class B extends A {
  int b() {
    return 38;
  }
}

class C {}

class T1 {
  late A getterField;
  A get field {
  //    ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.GETTER_NOT_SUBTYPE_SETTER_TYPES
  // [cfe] unspecified
    return getterField;
  }

  void set field(B arg) {
    getterField = arg;
  }
}

class T2 {
  late A getterField;
  late C setterField;
  A get field {
  //    ^^^^^
  // [analyzer] COMPILE_TIME_ERROR.GETTER_NOT_SUBTYPE_SETTER_TYPES
  // [cfe] unspecified
    return getterField;
  }

  // Type C is not assignable to A
  void set field(C arg) { setterField = arg; }
}

class T3 {
  late B getterField;
  B get field {
    return getterField;
  }

  void set field(A arg) {
    getterField = arg;
    //            ^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    // [cfe] A value of type 'A' can't be assigned to a variable of type 'B'.
  }
}

main() {
  T1 instance1 = new T1();
  T2 instance2 = new T2();
  T3 instance3 = new T3();

  instance1.field = new B();
  A resultA = instance1.field;
  Expect.throwsTypeError(() => instance1.field = new A() as dynamic);
  B resultB = instance1.field;
  //          ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //                    ^
  // [cfe] A value of type 'A' can't be assigned to a variable of type 'B'.

  int result;
  result = instance1.field.a();
  Expect.equals(37, result);

  // Type 'A' has no method named 'b'
  instance1.field.b();
  //              ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_METHOD
  // [cfe] The method 'b' isn't defined for the class 'A'.

  instance3.field = new B();
  result = instance3.field.a();
  Expect.equals(37, result);
  result = instance3.field.b();
  Expect.equals(38, result);
}
