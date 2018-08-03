// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test static warnings for method overrides.

class A {
  method1() => null; //# 01: ok
  method2(a) => null; //# 02: ok
  method3(a, b, c, d) => null; //# 03: ok
  method4() => null; //# 04: compile-time error
  method6(a, b, c) => null; //# 06: compile-time error
  method7([a]) => null; //# 07: ok
  method8([a, b]) => null; //# 08: ok
  method9([a, b, c]) => null; //# 09: ok
  method10([a]) => null; //# 10: ok
  method11(a) => null; //# 11: compile-time error
  method12(a, [b]) => null; //# 12: compile-time error
  method13(a, [b]) => null; //# 13: compile-time error
  method14(a, b, [c, d, e]) => null; //# 14: compile-time error
  method15({a}) => null; //# 15: ok
  method16({a, b}) => null; //# 16: ok
  method17({a, b, c}) => null; //# 17: ok
  method18(d, {a, b, c}) => null; //# 18: ok
  method19({a}) => null; //# 19: compile-time error
  method20({a, b}) => null; //# 20: compile-time error
  method21({a, b, c, d}) => null; //# 21: compile-time error

  method22(int a) => null; //# 22: ok
  method23(int a) => null; //# 23: ok
  void method24() {} //# 24: ok
  method25() => null; //# 25: ok
  void method26() {} //# 26: ok
  int method27() => null; //# 27: compile-time error
  method28(int a) => null; //# 28: ok
  method29(int a) => null; //# 29: ok
  method30(int a) => null; //# 30: compile-time error
}

class B extends A {
  method28(num a) => null; //# 28: continued
  method29(a) => null; //# 29: continued
}

abstract class I {
  method5() => null; //# 05: compile-time error
  method31(int a) => null; //# 31: compile-time error
  method32(int a) => null; //# 32: compile-time error
  method33(num a) => null; //# 33: compile-time error
}

abstract class J {
  method31(num a) => null; //# 31: continued
  method32(double a) => null; //# 32: continued
  method33(int a) => null; //# 33: continued
}

class Class extends B implements I, J {
  method1() => null; //# 01: continued
  method2(b) => null; //# 02: continued
  method3(b, a, d, c) => null; //# 03: continued
  method4(a) => null; //# 04: continued
  method5(a) => null; //# 05: continued
  method6(a, b, c, d) => null; //# 06: continued
  method7([a]) => null; //# 07: continued
  method8([b, a]) => null; //# 08: continued
  method9([b, d, a, c]) => null; //# 09: continued
  method10([a]) => null; //# 10: continued
  method11() => null; //# 11: continued
  method12(a) => null; //# 12: continued
  method13([a]) => null; //# 13: continued
  method14([a, b, c, d]) => null; //# 14: continued
  method15({a}) => null; //# 15: continued
  method16({b, a}) => null; //# 16: continued
  method17({b, c, a, d}) => null; //# 17: continued
  method18(e, {b, c, a, d}) => null; //# 18: continued
  method19() => null; //# 19: continued
  method20({b}) => null; //# 20: continued
  method21({a, e, d, c}) => null; //# 21: continued

  method22(int a) => null; //# 22: continued
  method23(num a) => null; //# 23: continued
  method24() => null; //# 24: continued
  void method25() {} //# 25: continued
  int method26() => null; //# 26: continued
  void method27() {} //# 27: continued
  method28(double a) => null; //# 28: continued
  method29(String a) => null; //# 29: continued
  method30(String a) => null; //# 30: continued
}

class SubClass extends Class {
  method31(double a) => null; //# 31: continued
  method32(String a) => null; //# 32: continued
  method33(double a) => null; //# 33: continued
}

main() {
  new SubClass();
}
