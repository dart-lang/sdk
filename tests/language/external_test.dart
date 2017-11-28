// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Bar {
  Bar(val);
}

class Foo {
  var x;
  f() {}

  Foo() : x = 0;

  external var x01; // //# 01: syntax error
  external int x02; // //# 02: syntax error

  external f10(); //  //# 10: runtime error
  external f11() { } // //# 11: syntax error
  external f12() => 1; // //# 12: syntax error
  external static f13(); // //# 13: runtime error
  static external f14(); // //# 14: syntax error
  int external f16(); // //# 16: syntax error

  external Foo.n20(val); // //# 20: runtime error
  external Foo.n21(val) : x = 1; // //# 21: syntax error
  external Foo.n22(val) { x = 1; } // //# 22: syntax error
  external factory Foo.n23(val) => new Foo(); // //# 23: syntax error
  external Foo.n24(this.x); // //# 24: compile-time error
  external factory Foo.n25(val) = Bar; // //# 25: syntax error
}

external int t06(int i) { } // //# 30: syntax error
external int t07(int i) => i + 1; // //# 31: syntax error

main() {
  // Ensure Foo class is compiled.
  var foo = new Foo();

  // Try calling an unpatched external function.
  new Foo().f10(); //                                   //# 10: continued
  new Foo().f11(); //                                   //# 11: continued
  new Foo().f12(); //                                   //# 12: continued
  Foo.f13(); //                                         //# 13: continued
  Foo.f14(); //                                         //# 14: continued
  new Foo().f16(); //                                   //# 16: continued

  // Try calling an unpatched external constructor.
  new Foo.n20(1); //                                     //# 20: continued
  new Foo.n21(1); //                                     //# 21: continued
  new Foo.n22(1); //                                     //# 22: continued
  new Foo.n23(1); //                                     //# 23: continued
  new Foo.n24(1); //                                     //# 24: continued
  new Foo.n25(1); //                                     //# 25: continued

  t06(1); //                                            //# 30: continued
  t07(1); //                                            //# 31: continued
}
