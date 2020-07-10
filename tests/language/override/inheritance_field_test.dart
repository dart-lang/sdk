// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  get getter1 => null; //# 01: ok
  num get getter2 => 0; //# 02: ok
  num get getter3 => 0; //# 03: ok
  int get getter4 => 0; //# 04: compile-time error
  int get getter5 => 0; //# 05: compile-time error
  int get getter6 => 0; //# 06: compile-time error
  int get getter7 => 0; //# 07: compile-time error
  int get getter8 => 0; //# 08: compile-time error

  set setter1(_) => null; //# 21: ok
  void set setter2(_) {} //# 22: ok
  set setter3(_) => null; //# 23: ok
  set setter4(_) => null; //# 24: ok
  set setter5(num _) => null; //# 25: ok
  set setter6(num _) => null; //# 26: compile-time error
  set setter7(int _) => null; //# 27: ok
  set setter8(int _) => null; //# 28: compile-time error
  set setter9(int _) => null; //# 29: compile-time error
  set setter10(int _) => null; //# 30: compile-time error
  set setter11(int _) => null; //# 31: compile-time error

  int field1 = 0; //# 41: ok
  num field2 = 0; //# 42: compile-time error
  int field3 = 0; //# 43: compile-time error
  int field4 = 0; //# 44: compile-time error
  int field5 = 0; //# 45: compile-time error
  num field6 = 0; //# 46: ok
  num field7 = 0; //# 47: compile-time error
  num get field8 => 0; //# 48: compile-time error
  num field9 = 0; //# 49: compile-time error
  num field10 = 0; //# 50: compile-time error
  set field11(int _) {} //# 51: ok
  void set field12(int _) {} //# 52: ok
  num field13 = 0; //# 53: compile-time error
  set field14(num _) {} //# 54: compile-time error
  num field15 = 0; //# 55: compile-time error
}

class B extends A {
  num get getter6 => 0; //# 06: continued
  set setter9(num _) => null; //# 29: continued
  num field5 = 0; //# 45: continued
}

abstract class I {
  num get getter7 => 0; //# 07: continued
  String get getter8 => ""; //# 08: continued
  int get getter9 => 0; //# 09: compile-time error
  int get getter10 => 0; //# 10: compile-time error
  int get getter11 => 0; //# 11: compile-time error
  set setter10(num _) => null; //# 30: continued
  set setter11(String _) => null; //# 31: continued
  set setter12(int _) => null; //# 32: compile-time error
  set setter13(int _) => null; //# 33: compile-time error
  set setter13(num _) => null; //# 33a: compile-time error
  set setter14(int _) => null; //# 34: compile-time error
}

abstract class J {
  String get getter9 => ""; //# 09: continued
  num get getter10 => 0; //# 10: continued
  num get getter11 => 0; //# 11: continued
  set setter12(String _) => null; //# 32: continued
  set setter13(num _) => null; //# 33: continued
  set setter13(int _) => null; //# 33a: continued
  set setter14(num _) => null; //# 34: continued
}

abstract class Class extends B implements I, J {
  get getter1 => null; //# 01: continued
  num get getter2 => 0; //# 02: continued
  int get getter3 => 0; //# 03: continued
  num get getter4 => 0; //# 04: continued
  double get getter5 => 0.0; //# 05: continued
  double get getter6 => 0.0; //# 06: continued
  double get getter7 => 0.0; //# 07: continued
  double get getter8 => 0.0; //# 08: continued
  double get getter9 => 0.0; //# 09: continued

  set setter1(_) => null; //# 21: continued
  set setter2(_) => null; //# 22: continued
  void set setter3(_) {} //# 23: continued
  void set setter4(_) {} //# 24: continued
  set setter5(num _) => null; //# 25: continued
  set setter6(int _) => null; //# 26: continued
  set setter7(num _) => null; //# 27: continued
  set setter8(double _) => null; //# 28: continued
  set setter9(double _) => null; //# 29: continued
  set setter10(double _) => null; //# 30: continued
  set setter11(double _) => null; //# 31: continued
  set setter12(double _) => null; //# 32: continued

  int field1 = 0; //# 41: continued
  int field2 = 0; //# 42: continued
  num field3 = 0; //# 43: continued
  double field4 = 0.0; //# 44: continued
  double field5 = 0.0; //# 45: continued
  int get field6 => 0; //# 46: continued
  String get field7 => ""; //# 47: continued
  String field8 = ""; //# 48: continued
  set field9(int _) {} //# 49: continued
  void set field10(int _) {} //# 50: continued
  num field11 = 0; //# 51: continued
  num field12 = 0; //# 52: continued
  set field13(String _) {} //# 53: continued
  String field14 = ""; //# 54: continued
  set field15(covariant int _) {} //# 55: continued
}

class SubClass extends Class {
  double get getter10 => 0.0; //# 10: continued
  String get getter11 => ""; //# 11: continued
  set setter13(double _) => null; //# 33: continued
  set setter13(double _) => null; //# 33a: continued
  set setter14(String _) => null; //# 34: continued
}

main() {
  new SubClass();
}
