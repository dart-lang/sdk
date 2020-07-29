// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify semantics of the ?. operator when it appears on the LHS of an
// assignment.

import "package:expect/expect.dart";
import "conditional_access_helper.dart" as h;

bad() {
  Expect.fail('Should not be executed');
}

class B {}

class C extends B {
  int v;
  C(this.v);
  static int staticInt;
}

class D {
  E v;
  D(this.v);
  static E staticE;
}

class E {
  G operator +(int i) => new I();
}

class F {}

class G extends E implements F {}

class H {}

class I extends G implements H {}

C nullC() => null;

main() {
  // Make sure the "none" test fails if assignment to "?." is not implemented.
  // This makes status files easier to maintain.
  nullC()?.v = 1;

  // e1?.v = e2 is equivalent to ((x) => x == null ? null : x.v = e2)(e1).
  Expect.equals(null, nullC()?.v = bad());
  { C c = new C(1); Expect.equals(2, c?.v = 2); Expect.equals(2, c.v); }

  // C?.v = e2 is equivalent to C.v = e2.
  { C.staticInt = 1; Expect.equals(2, C?.staticInt = 2); Expect.equals(2, C.staticInt); }
  { h.C.staticInt = 1; Expect.equals(2, h.C?.staticInt = 2); Expect.equals(2, h.C.staticInt); }

  // The static type of e1?.v = e2 is the static type of e2.
  { D d = new D(new E()); G g = new G(); F f = (d?.v = g); Expect.identical(f, g); }
  { D d = new D(new E()); E e = new G(); F f = (d?.v = e); }
  //                                            ^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //                                            ^
  // [cfe] A value of type 'E' can't be assigned to a variable of type 'F'.
  { D.staticE = new E(); G g = new G(); F f = (D?.staticE = g); Expect.identical(f, g); }
  { h.D.staticE = new h.E(); h.G g = new h.G(); h.F f = (h.D?.staticE = g); Expect.identical(f, g); }
  { D.staticE = new E(); E e = new G(); F f = (D?.staticE = e); }
  //                                           ^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //                                              ^
  // [cfe] A value of type 'E' can't be assigned to a variable of type 'F'.
  { h.D.staticE = new h.E(); h.E e = new h.G(); h.F f = (h.D?.staticE = e); }
  //                                                     ^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //                                                          ^
  // [cfe] A value of type 'E' can't be assigned to a variable of type 'F'.

  // Exactly the same errors that would be caused by e1.v = e2 are
  // also generated in the case of e1?.v = e2.
  Expect.equals(null, nullC()?.bad = bad());
  //                           ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_SETTER
  // [cfe] The setter 'bad' isn't defined for the class 'C'.
  { B b = new C(1); Expect.equals(2, b?.v = 2); }
  //                                    ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_SETTER
  // [cfe] The setter 'v' isn't defined for the class 'B'.

  // e1?.v op= e2 is equivalent to ((x) => x?.v = x.v op e2)(e1).
  Expect.equals(null, nullC()?.v += bad());
  { C c = new C(1); Expect.equals(3, c?.v += 2); Expect.equals(3, c.v); }

  // C?.v op= e2 is equivalent to C.v op= e2.
  { C.staticInt = 1; Expect.equals(3, C?.staticInt += 2); Expect.equals(3, C?.staticInt); }

  // The static type of e1?.v op= e2 is the static type of e1.v op e2.
  { D d = new D(new E()); F f = (d?.v += 1); Expect.identical(d.v, f); }
  { D.staticE = new E(); F f = (D?.staticE += 1); Expect.identical(D.staticE, f); }
  { h.D.staticE = new h.E(); h.F f = (h.D?.staticE += 1); Expect.identical(h.D.staticE, f); }

  // Let T be the static type of e1 and let y be a fresh variable of type T.
  // Exactly the same errors that would be caused by y.v op e2 are
  // also generated in the case of e1?.v op= e2.
  nullC()?.bad = bad();
  //       ^^^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_SETTER
  // [cfe] The setter 'bad' isn't defined for the class 'C'.
  { B b = new C(1); b?.v += 2; }
  //                   ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_GETTER
  // [cfe] The getter 'v' isn't defined for the class 'B'.
  //                   ^
  // [analyzer] COMPILE_TIME_ERROR.UNDEFINED_SETTER
  // [cfe] The setter 'v' isn't defined for the class 'B'.
  { D d = new D(new E()); F f = (d?.v += nullC()); }
  //                                     ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'C' can't be assigned to a variable of type 'int'.
  { D d = new D(new E()); H h = (d?.v += 1); }
  //                             ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //                             ^
  // [cfe] A value of type 'G' can't be assigned to a variable of type 'H'.
  { D.staticE = new E(); F f = (D?.staticE += nullC()); }
  //                                          ^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'C' can't be assigned to a variable of type 'int'.
  { h.D.staticE = new h.E(); h.F f = (h.D?.staticE += h.nullC()); }
  //                                                  ^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.ARGUMENT_TYPE_NOT_ASSIGNABLE
  // [cfe] A value of type 'C' can't be assigned to a variable of type 'int'.
  { D.staticE = new E(); H h = (D?.staticE += 1); }
  //                            ^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //                               ^
  // [cfe] A value of type 'G' can't be assigned to a variable of type 'H'.
  { h.D.staticE = new h.E(); h.H hh = (h.D?.staticE += 1); }
  //                                   ^^^^^^^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.INVALID_ASSIGNMENT
  //                                        ^
  // [cfe] A value of type 'G' can't be assigned to a variable of type 'H'.

  // '?.' cannot be used to assign to toplevel properties in libraries imported
  // via prefix.
  h?.topLevelVar = null;
//^
// [analyzer] COMPILE_TIME_ERROR.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT
// [cfe] A prefix can't be used with null-aware operators.
//               ^
// [cfe] Can't assign to this.
  h?.topLevelVar += null;
//^
// [analyzer] COMPILE_TIME_ERROR.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT
// [cfe] A prefix can't be used with null-aware operators.
//               ^
// [cfe] Can't assign to this.
  h?.topLevelVar ??= null;
//^
// [analyzer] COMPILE_TIME_ERROR.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT
// [cfe] A prefix can't be used with null-aware operators.
//               ^
// [cfe] Can't assign to this.
}
