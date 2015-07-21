// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify semantics of the ?. operator when it appears in a postincrement or
// preincrement expression (or a postdecrement or predecrement expression).

import "package:expect/expect.dart";

class C {
  int v;
  C(this.v);
  static var staticField;
}

class D {
  E v;
  D(this.v);
}

class E {
  G operator+(int i) => new I();
  G operator-(int i) => new I();
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
  Expect.equals(null, nullC()?.v++); /// 01: ok
  { C c = new C(1); Expect.equals(1, c?.v++); Expect.equals(2, c.v); } /// 02: ok

  // The static type of e1?.v++ is the same as the static type of e1.v.
  { E e1 = new E(); D d = new D(e1); E e2 = d?.v++; Expect.identical(e1, e2); } /// 03: ok
  { G g = new G(); D d = new D(g); F f = d?.v++; Expect.identical(f, g); } /// 04: static type warning

  // e1?.v-- is equivalent to ((x) => x == null ? null : x.v--)(e1).
  Expect.equals(null, nullC()?.v--); /// 05: ok
  { C c = new C(1); Expect.equals(1, c?.v--); Expect.equals(0, c.v); } /// 06: ok

  // The static type of e1?.v-- is the same as the static type of e1.v.
  { E e1 = new E(); D d = new D(e1); E e2 = d?.v--; Expect.identical(e1, e2); } /// 07: ok
  { G g = new G(); D d = new D(g); F f = d?.v--; Expect.identical(f, g); } /// 08: static type warning

  // ++e1?.v is equivalent to e1?.v += 1.
  Expect.equals(null, ++nullC()?.v); /// 09: ok
  { C c = new C(1); Expect.equals(2, ++c?.v); Expect.equals(2, c.v); } /// 10: ok

  // The static type of ++e1?.v is the same as the static type of e1.v + 1.
  { D d = new D(new E()); F f = ++d?.v; Expect.identical(d.v, f); } /// 11: ok
  { D d = new D(new E()); H h = ++d?.v; Expect.identical(d.v, h); } /// 12: static type warning

  // --e1?.v is equivalent to e1?.v += 1.
  Expect.equals(null, --nullC()?.v); /// 13: ok
  { C c = new C(1); Expect.equals(0, --c?.v); Expect.equals(0, c.v); } /// 14: ok

  // The static type of --e1?.v is the same as the static type of e1.v - 1.
  { D d = new D(new E()); F f = --d?.v; Expect.identical(d.v, f); } /// 15: ok
  { D d = new D(new E()); H h = --d?.v; Expect.identical(d.v, h); } /// 16: static type warning
}
