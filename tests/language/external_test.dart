// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Foo {
  var x;
  f() {}

  external var x01;  /// 01: compile-time error
  external int x02;  /// 02: compile-time error

  external f10();   /// 10: runtime error
  external f11() { }  /// 11: compile-time error
  external f12() => 1;  /// 12: compile-time error
  external static f13();  /// 13: runtime error
  static external f14();  /// 14: compile-time error
  external abstract f15();  /// 15: compile-time error
  int external f16();  /// 16: compile-time error

  external Foo.n20();  /// 20: runtime error
  external Foo.n21() : x(1);  /// 21: compile-time error
  external Foo.n22() { x = 1; }  /// 22: compile-time error
  external factory Foo.n23() => new Foo();  /// 23: compile-time error
}

external int t06(int i) { }  /// 30: compile-time error
external int t07(int i) => i + 1;  /// 31: compile-time error

main() {

  // Try calling an unpatched external function.
  var foo = new Foo();                                /// 10: continued
  try {                                               /// 10: continued
    foo.f05();                                        /// 10: continued
  } on String catch (exc) {                           /// 10: continued
    if (exc == "External implementation missing.") {  /// 10: continued
      throw exc;                                      /// 10: continued
    }                                                 /// 10: continued
  }                                                   /// 10: continued

  try {                                               /// 13: continued
    Foo.f13();                                        /// 13: continued
  } on String catch (exc) {                           /// 13: continued
    if (exc == "External implementation missing.") {  /// 13: continued
      throw exc;                                      /// 13: continued
    }                                                 /// 13: continued
  }                                                   /// 13: continued

  // Try calling an unpatched external constructor.
  try {                                               /// 20: continued
    var foo = new Foo.n09();                          /// 20: continued
  } on String catch (exc) {                           /// 20: continued
    if (exc == "External implementation missing.") {  /// 20: continued
      throw exc;                                      /// 20: continued
    }                                                 /// 20: continued
  }                                                   /// 20: continued
}
