// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class M0 {
  factory M0(a, b, c) => null;
  factory M0.named() => null;
}

class M1 {
  M1();
}

class M2 {
  M2.named();
}

class C0 = Object with M0;
class C1 = Object with M1; //     //# 01: compile-time error
class C2 = Object with M2; //     //# 02: compile-time error
class C3 = Object with M0, M1; // //# 03: compile-time error
class C4 = Object with M1, M0; // //# 04: compile-time error
class C5 = Object with M0, M2; // //# 05: compile-time error
class C6 = Object with M2, M0; // //# 06: compile-time error

class D0 extends Object with M0 {}
class D1 extends Object with M1 { } //     //# 07: compile-time error
class D2 extends Object with M2 { } //     //# 08: compile-time error
class D3 extends Object with M0, M1 { } // //# 09: compile-time error
class D4 extends Object with M1, M0 { } // //# 10: compile-time error
class D5 extends Object with M0, M2 { } // //# 11: compile-time error
class D6 extends Object with M2, M0 { } // //# 12: compile-time error

main() {
  new C0();
  new C1(); // //# 01: continued
  new C2(); // //# 02: continued
  new C3(); // //# 03: continued
  new C4(); // //# 04: continued
  new C5(); // //# 05: continued
  new C6(); // //# 06: continued

  new D0();
  new D1(); // //# 07: continued
  new D2(); // //# 08: continued
  new D3(); // //# 09: continued
  new D4(); // //# 10: continued
  new D5(); // //# 11: continued
  new D6(); // //# 12: continued

  new C0(1,2,3); //  //# 13: compile-time error
  new C0.named(); // //# 14: compile-time error
  new D0(1,2,3); //  //# 15: compile-time error
  new D0.named(); // //# 16: compile-time error
}
