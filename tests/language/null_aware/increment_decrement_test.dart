// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify semantics of the ?. operator when it appears in a postincrement or
// preincrement expression (or a postdecrement or predecrement expression).

import "package:expect/expect.dart";
import "conditional_access_helper.dart" as h;

class C {
  int v;
  C(this.v);
  static late int staticInt;
}

class D {
  E v;
  D(this.v);
  static late E staticE;
}

class E {
  G operator +(int i) => new I();
  G operator -(int i) => new I();
}

class F {}

class G extends E implements F {}

class H {}

class I extends G implements H {}

C? nullC() => null;

main() {
  // Make sure the "none" test fails if assignment to "?." is not implemented.
  // This makes status files easier to maintain.
  nullC()?.v = 1;

  // e1?.v++ is equivalent to ((x) => x == null ? null : x.v++)(e1).
  Expect.equals(null, nullC()?.v++);
  {
    var c = new C(1) as C?;
    Expect.equals(1, c?.v++);
    Expect.equals(2, c!.v);
  }

  // C?.v++ is equivalent to C.v++.
  {
    C.staticInt = 1;
    Expect.equals(1, C?.staticInt++);
    //               ^
    // [cfe] The class 'C' cannot be null.
    Expect.equals(2, C.staticInt);
  }
  {
    h.C.staticInt = 1;
    Expect.equals(1, h.C?.staticInt++);
    //                 ^
    // [cfe] The class 'C' cannot be null.
    Expect.equals(2, h.C.staticInt);
  }

  // The static type of e1?.v++ is the same as the static type of e1.v.
  {
    E e1 = new E();
    var d = new D(e1) as D?;
    E? e2 = d?.v++;
    Expect.identical(e1, e2);
  }
  {
    G g = new G();
    var d = new D(g) as D?;
    F? f = d?.v++;
    //     ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    // [cfe] A value of type 'E?' can't be assigned to a variable of type 'F?'.
    Expect.identical(f, g);
  }
  {
    E e1 = new E();
    D.staticE = e1;
    E? e2 = D?.staticE++;
    //      ^
    // [cfe] The class 'D' cannot be null.
    Expect.identical(e1, e2);
  }
  {
    h.E e1 = new h.E();
    h.D.staticE = e1;
    h.E? e2 = h.D?.staticE++;
    //          ^
    // [cfe] The class 'D' cannot be null.
    Expect.identical(e1, e2);
  }
  {
    G g = new G();
    D.staticE = g;
    F? f = D?.staticE++;
    //     ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    // [cfe] The class 'D' cannot be null.
    //               ^
    // [cfe] A value of type 'E' can't be assigned to a variable of type 'F?'.
    Expect.identical(f, g);
  }
  {
    h.G g = new h.G();
    h.D.staticE = g;
    h.F? f = h.D?.staticE++;
    //       ^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //         ^
    // [cfe] The class 'D' cannot be null.
    //                   ^
    // [cfe] A value of type 'E' can't be assigned to a variable of type 'F?'.
    Expect.identical(f, g);
  }

  // e1?.v-- is equivalent to ((x) => x == null ? null : x.v--)(e1).
  Expect.equals(null, nullC()?.v--);
  {
    var c = new C(1) as C?;
    Expect.equals(1, c?.v--);
    Expect.equals(0, c!.v);
  }

  // C?.v-- is equivalent to C.v--.
  {
    C.staticInt = 1;
    Expect.equals(1, C?.staticInt--);
    //               ^
    // [cfe] The class 'C' cannot be null.
    Expect.equals(0, C.staticInt);
  }
  {
    h.C.staticInt = 1;
    Expect.equals(1, h.C?.staticInt--);
    //                 ^
    // [cfe] The class 'C' cannot be null.
    Expect.equals(0, h.C.staticInt);
  }

  // The static type of e1?.v-- is the same as the static type of e1.v.
  {
    E e1 = new E();
    var d = new D(e1) as D?;
    E? e2 = d?.v--;
    Expect.identical(e1, e2);
  }
  {
    G g = new G();
    var d = new D(g) as D?;
    F? f = d?.v--;
    //     ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    // [cfe] A value of type 'E?' can't be assigned to a variable of type 'F?'.
    Expect.identical(f, g);
  }
  {
    E e1 = new E();
    D.staticE = e1;
    E? e2 = D?.staticE--;
    //      ^
    // [cfe] The class 'D' cannot be null.
    Expect.identical(e1, e2);
  }
  {
    h.E e1 = new h.E();
    h.D.staticE = e1;
    h.E? e2 = h.D?.staticE--;
    //          ^
    // [cfe] The class 'D' cannot be null.
    Expect.identical(e1, e2);
  }
  {
    G g = new G();
    D.staticE = g;
    F? f = D?.staticE--;
    //     ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    // [cfe] The class 'D' cannot be null.
    //               ^
    // [cfe] A value of type 'E' can't be assigned to a variable of type 'F?'.
    Expect.identical(f, g);
  }
  {
    h.G g = new h.G();
    h.D.staticE = g;
    h.F? f = h.D?.staticE--;
    //       ^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //         ^
    // [cfe] The class 'D' cannot be null.
    //                   ^
    // [cfe] A value of type 'E' can't be assigned to a variable of type 'F?'.
    Expect.identical(f, g);
  }

  // ++e1?.v is equivalent to e1?.v += 1.
  Expect.equals(null, ++nullC()?.v);
  {
    var c = new C(1) as C?;
    Expect.equals(2, ++c?.v);
    Expect.equals(2, c!.v);
  }

  // ++C?.v is equivalent to C?.v += 1.
  {
    C.staticInt = 1;
    Expect.equals(2, ++C?.staticInt);
    //                 ^
    // [cfe] The class 'C' cannot be null.
    Expect.equals(2, C.staticInt);
  }
  {
    h.C.staticInt = 1;
    Expect.equals(2, ++h.C?.staticInt);
    //                   ^
    // [cfe] The class 'C' cannot be null.
    Expect.equals(2, h.C.staticInt);
  }

  // The static type of ++e1?.v is the same as the static type of e1.v + 1.
  {
    var d = new D(new E()) as D?;
    F? f = ++d?.v;
    Expect.identical(d!.v, f);
  }
  {
    var d = new D(new E()) as D?;
    H? h = ++d?.v;
    //     ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //       ^
    // [cfe] A value of type 'G?' can't be assigned to a variable of type 'H?'.
    Expect.identical(d!.v, h);
  }
  {
    D.staticE = new E();
    F? f = ++D?.staticE;
    //       ^
    // [cfe] The class 'D' cannot be null.
    Expect.identical(D.staticE, f);
  }
  {
    h.D.staticE = new h.E();
    h.F? f = ++h.D?.staticE;
    //           ^
    // [cfe] The class 'D' cannot be null.
    Expect.identical(h.D.staticE, f);
  }
  {
    D.staticE = new E();
    H? h = ++D?.staticE;
    //     ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //       ^
    // [cfe] The class 'D' cannot be null.
    //          ^
    // [cfe] A value of type 'G' can't be assigned to a variable of type 'H?'.
    Expect.identical(D.staticE, h);
  }
  {
    h.D.staticE = new h.E();
    h.H? hh = ++h.D?.staticE;
    //        ^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //            ^
    // [cfe] The class 'D' cannot be null.
    //               ^
    // [cfe] A value of type 'G' can't be assigned to a variable of type 'H?'.
    Expect.identical(h.D.staticE, hh);
  }

  // --e1?.v is equivalent to e1?.v -= 1.
  Expect.equals(null, --nullC()?.v);
  {
    var c = new C(1) as C?;
    Expect.equals(0, --c?.v);
    Expect.equals(0, c!.v);
  }

  // --C?.v is equivalent to C?.v -= 1.
  {
    C.staticInt = 1;
    Expect.equals(0, --C?.staticInt);
    //                 ^
    // [cfe] The class 'C' cannot be null.
    Expect.equals(0, C.staticInt);
  }
  {
    h.C.staticInt = 1;
    Expect.equals(0, --h.C?.staticInt);
    //                   ^
    // [cfe] The class 'C' cannot be null.
    Expect.equals(0, h.C.staticInt);
  }

  // The static type of --e1?.v is the same as the static type of e1.v - 1.
  {
    var d = new D(new E()) as D?;
    F? f = --d?.v;
    Expect.identical(d!.v, f);
  }
  {
    var d = new D(new E()) as D?;
    H? h = --d?.v;
    //     ^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //       ^
    // [cfe] A value of type 'G?' can't be assigned to a variable of type 'H?'.
    Expect.identical(d!.v, h);
  }
  {
    D.staticE = new E();
    F? f = --D?.staticE;
    //       ^
    // [cfe] The class 'D' cannot be null.
    Expect.identical(D.staticE, f);
  }
  {
    h.D.staticE = new h.E();
    h.F? f = --h.D?.staticE;
    //           ^
    // [cfe] The class 'D' cannot be null.
    Expect.identical(h.D.staticE, f);
  }
  {
    D.staticE = new E();
    H? h = --D?.staticE;
    //     ^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //       ^
    // [cfe] The class 'D' cannot be null.
    //          ^
    // [cfe] A value of type 'G' can't be assigned to a variable of type 'H?'.
    Expect.identical(D.staticE, h);
  }
  {
    h.D.staticE = new h.E();
    h.H? hh = --h.D?.staticE;
    //        ^^^^^^^^^^^^^^
    // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
    //            ^
    // [cfe] The class 'D' cannot be null.
    //               ^
    // [cfe] A value of type 'G' can't be assigned to a variable of type 'H?'.
    Expect.identical(h.D.staticE, hh);
  }
}
