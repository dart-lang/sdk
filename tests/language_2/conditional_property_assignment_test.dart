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

noMethod(e) => e is NoSuchMethodError;

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
  Expect.equals(null, nullC()?.v = bad()); //# 01: ok
  { C c = new C(1); Expect.equals(2, c?.v = 2); Expect.equals(2, c.v); } //# 02: ok

  // C?.v = e2 is equivalent to C.v = e2.
  { C.staticInt = 1; Expect.equals(2, C?.staticInt = 2); Expect.equals(2, C.staticInt); } //# 23: ok
  { h.C.staticInt = 1; Expect.equals(2, h.C?.staticInt = 2); Expect.equals(2, h.C.staticInt); } //# 24: ok

  // The static type of e1?.v = e2 is the static type of e2.
  { D d = new D(new E()); G g = new G(); F f = (d?.v = g); Expect.identical(f, g); } //# 03: ok
  { D d = new D(new E()); E e = new G(); F f = (d?.v = e); } //# 04: compile-time error
  { D.staticE = new E(); G g = new G(); F f = (D?.staticE = g); Expect.identical(f, g); } //# 25: ok
  { h.D.staticE = new h.E(); h.G g = new h.G(); h.F f = (h.D?.staticE = g); Expect.identical(f, g); } //# 26: ok
  { D.staticE = new E(); E e = new G(); F f = (D?.staticE = e); } //# 27: compile-time error
  { h.D.staticE = new h.E(); h.E e = new h.G(); h.F f = (h.D?.staticE = e); } //# 28: compile-time error

  // Exactly the same errors that would be caused by e1.v = e2 are
  // also generated in the case of e1?.v = e2.
  Expect.equals(null, nullC()?.bad = bad()); //# 05: compile-time error
  { B b = new C(1); Expect.equals(2, b?.v = 2); } //# 06: compile-time error

  // e1?.v op= e2 is equivalent to ((x) => x?.v = x.v op e2)(e1).
  Expect.equals(null, nullC()?.v += bad()); //# 07: ok
  { C c = new C(1); Expect.equals(3, c?.v += 2); Expect.equals(3, c.v); } //# 08: ok

  // C?.v op= e2 is equivalent to C.v op= e2.
  { C.staticInt = 1; Expect.equals(3, C?.staticInt += 2); Expect.equals(3, C?.staticInt); } //# 29: ok

  // The static type of e1?.v op= e2 is the static type of e1.v op e2.
  { D d = new D(new E()); F f = (d?.v += 1); Expect.identical(d.v, f); } //# 09: ok
  { D.staticE = new E(); F f = (D?.staticE += 1); Expect.identical(D.staticE, f); } //# 30: ok
  { h.D.staticE = new h.E(); h.F f = (h.D?.staticE += 1); Expect.identical(h.D.staticE, f); } //# 31: ok

  // Let T be the static type of e1 and let y be a fresh variable of type T.
  // Exactly the same errors that would be caused by y.v op e2 are
  // also generated in the case of e1?.v op= e2.
  nullC()?.bad = bad(); //# 10: compile-time error
  { B b = new C(1); b?.v += 2; } //# 11: compile-time error
  { D d = new D(new E()); F f = (d?.v += nullC()); } //# 12: compile-time error
  { D d = new D(new E()); H h = (d?.v += 1); } //# 13: compile-time error
  { D.staticE = new E(); F f = (D?.staticE += nullC()); } //# 32: compile-time error
  { h.D.staticE = new h.E(); h.F f = (h.D?.staticE += h.nullC()); } //# 33: compile-time error
  { D.staticE = new E(); H h = (D?.staticE += 1); } //# 34: compile-time error
  { h.D.staticE = new h.E(); h.H hh = (h.D?.staticE += 1); } //# 35: compile-time error

  // '?.' cannot be used to assign to toplevel properties in libraries imported
  // via prefix.
  h?.topLevelVar = null; //# 20: compile-time error
  h?.topLevelVar += null; //# 21: compile-time error
  h?.topLevelVar ??= null; //# 22: compile-time error
}
