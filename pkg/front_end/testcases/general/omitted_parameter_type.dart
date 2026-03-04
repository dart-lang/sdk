// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

typedef void Typedef1(a,{b});

method0(a, {b = 0}) {
  int x = a;
  String y = a; // Ok
  int z = b;
  String w = b; // Ok
}

class SuperClass {
  void method(void f(a,{b})) {

    local(a, {b = 0}) {
      int x = a;
      String y = a; // Ok
      int z = b;
      String w = b; // Ok
    }

    try {} catch (e, s) {}
  }

  void method1(int a, {int? b}) {}
}

class SubClass extends SuperClass {
  SubClass();

  SubClass.constructor1(a, {b = 0}) {
    int x = a;
    String y = a; // Ok
    int z = b;
    String w = b; // Ok
  }

  SubClass.constructor2(int x, String y, int z, String w);

  SubClass.constructor3(a, {b = 0}) : this.constructor2(a, a, b, b); // Ok

  factory SubClass.constructor4(a, {b = 0}) {
    int x = a;
    String y = a; // Ok
    int z = b;
    String w = b; // Ok

    return SubClass();
  }

  method1(a, {b}) {
    int x = a;
    String y = a; // Error
    int? z = b;
    String? w = b; // Error
  }

  method2(a, {b = 0}) {
    int x = a;
    String y = a; // Ok
    int z = b;
    String w = b; // Ok
  }

  static method3(a, {b = 0}) {
    int x = a;
    String y = a; // Ok
    int z = b;
    String w = b; // Ok
  }
}

extension on int {
  method1(a, {b = 0}) {
    int x = a;
    String y = a; // Ok
    int z = b;
    String w = b; // Ok
  }

  static method2(a, {b = 0}) {
    int x = a;
    String y = a; // Ok
    int z = b;
    String w = b; // Ok
  }
}

extension type SuperExtensionType(int i) {
  void method3(int a, {int? b}) {}
}

extension type SubExtensionType(int i) implements SuperExtensionType {
  method3(a, {b}) {
    int x = a;
    String y = a; // Ok
    int? z = b;
    String? w = b; // Ok
  }

  method4(a, {b = 0}) {
    int x = a;
    String y = a; // Ok
    int z = b;
    String w = b; // Ok
  }
}
