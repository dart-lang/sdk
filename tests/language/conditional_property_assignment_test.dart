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
  static var staticField;
}

class D {
  E v;
  D(this.v);
}

class E {
  G operator+(int i) => new I();
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
  Expect.equals(null, nullC()?.v = bad()); /// 01: ok
  { C c = new C(1); Expect.equals(2, c?.v = 2); Expect.equals(2, c.v); } /// 02: ok

  // The static type of e1?.v = e2 is the static type of e2.
  { D d = new D(new E()); G g = new G(); F f = (d?.v = g); Expect.identical(f, g); } /// 03: ok
  { D d = new D(new E()); E e = new G(); F f = (d?.v = e); Expect.identical(f, e); } /// 04: static type warning

  // Exactly the same static warnings that would be caused by e1.v = e2 are
  // also generated in the case of e1?.v = e2.
  Expect.equals(null, nullC()?.bad = bad()); /// 05: static type warning
  { B b = new C(1); Expect.equals(2, b?.v = 2); Expect.equals(2, (b as C).v); } /// 06: static type warning

  // e1?.v op= e2 is equivalent to ((x) => x?.v = x.v op e2)(e1).
  Expect.equals(null, nullC()?.v += bad()); /// 07: ok
  { C c = new C(1); Expect.equals(3, c?.v += 2); Expect.equals(3, c.v); } /// 08: ok

  // The static type of e1?.v op= e2 is the static type of e1.v op e2.
  { D d = new D(new E()); F f = (d?.v += 1); Expect.identical(d.v, f); } /// 09: ok

  // Let T be the static type of e1 and let y be a fresh variable of type T.
  // Exactly the same static warnings that would be caused by y.v op e2 are
  // also generated in the case of e1?.v op= e2.
  Expect.equals(null, nullC()?.bad = bad()); /// 10: static type warning
  { B b = new C(1); Expect.equals(3, b?.v += 2); Expect.equals(3, (b as C).v); } /// 11: static type warning
  { D d = new D(new E()); F f = (d?.v += nullC()); Expect.identical(d.v, f); } /// 12: static type warning
  { D d = new D(new E()); H h = (d?.v += 1); Expect.identical(d.v, h); } /// 13: static type warning

  // Consequently, '?.' cannot be used to assign to static properties of
  // classes.
  Expect.throws(() => C?.staticField = null, noMethod); /// 14: static type warning
  Expect.throws(() => C?.staticField += null, noMethod); /// 15: static type warning
  Expect.throws(() => C?.staticField ??= null, noMethod); /// 16: static type warning
  Expect.throws(() => h.C?.staticField = null, noMethod); /// 17: static type warning
  Expect.throws(() => h.C?.staticField += null, noMethod); /// 18: static type warning
  Expect.throws(() => h.C?.staticField ??= null, noMethod); /// 19: static type warning

  // Nor can it be used to assign to toplevel properties in libraries imported
  // via prefix.
  h?.topLevelVar = null; /// 20: compile-time error
  h?.topLevelVar += null; /// 21: compile-time error
  h?.topLevelVar ??= null; /// 22: compile-time error
}
