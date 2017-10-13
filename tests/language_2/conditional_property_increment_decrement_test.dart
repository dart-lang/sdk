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
  static int staticInt;
}

class D {
  E v;
  D(this.v);
  static E staticE;
}

class E {
  G operator +(int i) => new I();
  G operator -(int i) => new I();
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

  // e1?.v++ is equivalent to ((x) => x == null ? null : x.v++)(e1).
  Expect.equals(null, nullC()?.v++); //# 01: ok
  { C c = new C(1); Expect.equals(1, c?.v++); Expect.equals(2, c.v); } //# 02: ok

  // C?.v++ is equivalent to C.v++.
  { C.staticInt = 1; Expect.equals(1, C?.staticInt++); Expect.equals(2, C.staticInt); } //# 17: ok
  { h.C.staticInt = 1; Expect.equals(1, h.C?.staticInt++); Expect.equals(2, h.C.staticInt); } //# 18: ok

  // The static type of e1?.v++ is the same as the static type of e1.v.
  { E e1 = new E(); D d = new D(e1); E e2 = d?.v++; Expect.identical(e1, e2); } //# 03: ok
  { G g = new G(); D d = new D(g); F f = d?.v++; Expect.identical(f, g); } //# 04: compile-time error
  { E e1 = new E(); D.staticE = e1; E e2 = D?.staticE++; Expect.identical(e1, e2); } //# 19: ok
  { h.E e1 = new h.E(); h.D.staticE = e1; h.E e2 = h.D?.staticE++; Expect.identical(e1, e2); } //# 20: ok
  { G g = new G(); D.staticE = g; F f = D?.staticE++; Expect.identical(f, g); } //# 21: compile-time error
  { h.G g = new h.G(); h.D.staticE = g; h.F f = h.D?.staticE++; Expect.identical(f, g); } //# 22: compile-time error

  // e1?.v-- is equivalent to ((x) => x == null ? null : x.v--)(e1).
  Expect.equals(null, nullC()?.v--); //# 05: ok
  { C c = new C(1); Expect.equals(1, c?.v--); Expect.equals(0, c.v); } //# 06: ok

  // C?.v-- is equivalent to C.v--.
  { C.staticInt = 1; Expect.equals(1, C?.staticInt--); Expect.equals(0, C.staticInt); } //# 23: ok
  { h.C.staticInt = 1; Expect.equals(1, h.C?.staticInt--); Expect.equals(0, h.C.staticInt); } //# 24: ok

  // The static type of e1?.v-- is the same as the static type of e1.v.
  { E e1 = new E(); D d = new D(e1); E e2 = d?.v--; Expect.identical(e1, e2); } //# 07: ok
  { G g = new G(); D d = new D(g); F f = d?.v--; Expect.identical(f, g); } //# 08: compile-time error
  { E e1 = new E(); D.staticE = e1; E e2 = D?.staticE--; Expect.identical(e1, e2); } //# 25: ok
  { h.E e1 = new h.E(); h.D.staticE = e1; h.E e2 = h.D?.staticE--; Expect.identical(e1, e2); } //# 26: ok
  { G g = new G(); D.staticE = g; F f = D?.staticE--; Expect.identical(f, g); } //# 27: compile-time error
  { h.G g = new h.G(); h.D.staticE = g; h.F f = h.D?.staticE--; Expect.identical(f, g); } //# 28: compile-time error

  // ++e1?.v is equivalent to e1?.v += 1.
  Expect.equals(null, ++nullC()?.v); //# 09: ok
  { C c = new C(1); Expect.equals(2, ++c?.v); Expect.equals(2, c.v); } //# 10: ok

  // ++C?.v is equivalent to C?.v += 1.
  { C.staticInt = 1; Expect.equals(2, ++C?.staticInt); Expect.equals(2, C.staticInt); } //# 29: ok
  { h.C.staticInt = 1; Expect.equals(2, ++h.C?.staticInt); Expect.equals(2, h.C.staticInt); } //# 30: ok

  // The static type of ++e1?.v is the same as the static type of e1.v + 1.
  { D d = new D(new E()); F f = ++d?.v; Expect.identical(d.v, f); } //# 11: ok
  { D d = new D(new E()); H h = ++d?.v; Expect.identical(d.v, h); } //# 12: compile-time error
  { D.staticE = new E(); F f = ++D?.staticE; Expect.identical(D.staticE, f); } //# 31: ok
  { h.D.staticE = new h.E(); h.F f = ++h.D?.staticE; Expect.identical(h.D.staticE, f); } //# 32: ok
  { D.staticE = new E(); H h = ++D?.staticE; Expect.identical(D.staticE, h); } //# 33: compile-time error
  { h.D.staticE = new h.E(); h.H hh = ++h.D?.staticE; Expect.identical(h.D.staticE, hh); } //# 34: compile-time error

  // --e1?.v is equivalent to e1?.v -= 1.
  Expect.equals(null, --nullC()?.v); //# 13: ok
  { C c = new C(1); Expect.equals(0, --c?.v); Expect.equals(0, c.v); } //# 14: ok

  // --C?.v is equivalent to C?.v -= 1.
  { C.staticInt = 1; Expect.equals(0, --C?.staticInt); Expect.equals(0, C.staticInt); } //# 35: ok
  { h.C.staticInt = 1; Expect.equals(0, --h.C?.staticInt); Expect.equals(0, h.C.staticInt); } //# 36: ok

  // The static type of --e1?.v is the same as the static type of e1.v - 1.
  { D d = new D(new E()); F f = --d?.v; Expect.identical(d.v, f); } //# 15: ok
  { D d = new D(new E()); H h = --d?.v; Expect.identical(d.v, h); } //# 16: compile-time error
  { D.staticE = new E(); F f = --D?.staticE; Expect.identical(D.staticE, f); } //# 37: ok
  { h.D.staticE = new h.E(); h.F f = --h.D?.staticE; Expect.identical(h.D.staticE, f); } //# 38: ok
  { D.staticE = new E(); H h = --D?.staticE; Expect.identical(D.staticE, h); } //# 39: compile-time error
  { h.D.staticE = new h.E(); h.H hh = --h.D?.staticE; Expect.identical(h.D.staticE, hh); } //# 40: compile-time error
}
