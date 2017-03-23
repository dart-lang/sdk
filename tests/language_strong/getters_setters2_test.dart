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
  A getterField;
  A get field {
    return getterField;
  }

  // OK, B is assignable to A
  void set field(B arg) {
    getterField = arg;
  }
}

class T2 {
  A getterField;
  C setterField;
  A get field {
    return getterField;
  }

  // Type C is not assignable to A
  void set field(C arg) { setterField = arg; } //# 01: static type warning
}

class T3 {
  B getterField;
  B get field {
    return getterField;
  }

  // OK, A is assignable to B
  void set field(A arg) {
    getterField = arg;
  }
}

main() {
  T1 instance1 = new T1();
  T2 instance2 = new T2(); //# 01: continued
  T3 instance3 = new T3();

  instance1.field = new B();
  A resultA = instance1.field;
  instance1.field = new A(); //# 03: dynamic type error
  B resultB = instance1.field;

  int result;
  result = instance1.field.a();
  Expect.equals(37, result);

  // Type 'A' has no method named 'b'
  instance1.field.b(); //# 02: static type warning

  instance3.field = new B();
  result = instance3.field.a();
  Expect.equals(37, result);
  result = instance3.field.b();
  Expect.equals(38, result);
}
