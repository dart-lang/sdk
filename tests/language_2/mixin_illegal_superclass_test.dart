// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class S0 {}

class S1 extends Object {}

class S2 extends S0 {}

class M0 {}

class M1 extends Object {}

class M2 extends M0 {}

class C00 = S0 with M0;
class C01 = S0 with M1;
class C02 = S0 with M2; //     //# 01: compile-time error
class C03 = S0 with M0, M1;
class C04 = S0 with M0, M2; // //# 02: compile-time error
class C05 = S0 with M2, M0; // //# 03: compile-time error
class C06 = S0 with M1, M2; // //# 04: compile-time error
class C07 = S0 with M2, M1; // //# 05: compile-time error

class C10 = S1 with M0;
class C11 = S1 with M1;
class C12 = S1 with M2; //     //# 06: compile-time error
class C13 = S1 with M0, M1;
class C14 = S1 with M0, M2; // //# 07: compile-time error
class C15 = S1 with M2, M0; // //# 08: compile-time error
class C16 = S1 with M1, M2; // //# 09: compile-time error
class C17 = S1 with M2, M1; // //# 10: compile-time error

class C20 = S2 with M0;
class C21 = S2 with M1;
class C22 = S2 with M2; //     //# 11: compile-time error
class C23 = S2 with M0, M1;
class C24 = S2 with M0, M2; // //# 12: compile-time error
class C25 = S2 with M2, M0; // //# 13: compile-time error
class C26 = S2 with M1, M2; // //# 14: compile-time error
class C27 = S2 with M2, M1; // //# 15: compile-time error

class D00 extends S0 with M0 {}

class D01 extends S0 with M1 {}

class D02 extends S0 with M2 { } //     //# 16: compile-time error
class D03 extends S0 with M0, M1 {}
class D04 extends S0 with M0, M2 { } // //# 17: compile-time error
class D05 extends S0 with M2, M0 { } // //# 18: compile-time error
class D06 extends S0 with M1, M2 { } // //# 19: compile-time error
class D07 extends S0 with M2, M1 { } // //# 20: compile-time error

class D10 extends S1 with M0 {}

class D11 extends S1 with M1 {}

class D12 extends S1 with M2 { } //     //# 21: compile-time error
class D13 extends S1 with M0, M1 {}
class D14 extends S1 with M0, M2 { } // //# 22: compile-time error
class D15 extends S1 with M2, M0 { } // //# 23: compile-time error
class D16 extends S1 with M1, M2 { } // //# 24: compile-time error
class D17 extends S1 with M2, M1 { } // //# 25: compile-time error

class D20 extends S2 with M0 {}

class D21 extends S2 with M1 {}

class D22 extends S2 with M2 { } //     //# 26: compile-time error
class D23 extends S2 with M0, M1 {}
class D24 extends S2 with M0, M2 { } // //# 27: compile-time error
class D25 extends S2 with M2, M0 { } // //# 28: compile-time error
class D26 extends S2 with M1, M2 { } // //# 29: compile-time error
class D27 extends S2 with M2, M1 { } // //# 30: compile-time error

main() {
  new C00();
  new C01();
  new C02(); // //# 01: continued
  new C03();
  new C04(); // //# 02: continued
  new C05(); // //# 03: continued
  new C06(); // //# 04: continued
  new C07(); // //# 05: continued

  new C10();
  new C11();
  new C12(); // //# 06: continued
  new C13();
  new C14(); // //# 07: continued
  new C15(); // //# 08: continued
  new C16(); // //# 09: continued
  new C17(); // //# 10: continued

  new C20();
  new C21();
  new C22(); // //# 11: continued
  new C23();
  new C24(); // //# 12: continued
  new C25(); // //# 13: continued
  new C26(); // //# 14: continued
  new C27(); // //# 15: continued

  new D00();
  new D01();
  new D02(); // //# 16: continued
  new D03();
  new D04(); // //# 17: continued
  new D05(); // //# 18: continued
  new D06(); // //# 19: continued
  new D07(); // //# 20: continued

  new D10();
  new D11();
  new D12(); // //# 21: continued
  new D13();
  new D14(); // //# 22: continued
  new D15(); // //# 23: continued
  new D16(); // //# 24: continued
  new D17(); // //# 25: continued

  new D20();
  new D21();
  new D22(); // //# 26: continued
  new D23();
  new D24(); // //# 27: continued
  new D25(); // //# 28: continued
  new D26(); // //# 29: continued
  new D27(); // //# 30: continued
}
