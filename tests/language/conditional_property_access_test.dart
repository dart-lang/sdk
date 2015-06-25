// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify semantics of the ?. operator when it does not appear on the LHS of an
// assignment.

// SharedOptions=--enable-null-aware-operators

import "package:expect/expect.dart";
import "conditional_access_helper.dart" as h;

noMethod(e) => e is NoSuchMethodError;

class B {}

class C extends B {
  int v;
  C(this.v);
  static var staticField;
}

C nullC() => null;

main() {
  // Make sure the "none" test fails if property access using "?." is not
  // implemented.  This makes status files easier to maintain.
  nullC()?.v;

  // e1?.id is equivalent to ((x) => x == null ? null : x.id)(e1).
  Expect.equals(null, nullC()?.v); /// 01: ok
  Expect.equals(1, new C(1)?.v); /// 02: ok

  // The static type of e1?.d is the static type of e1.id.
  { int i = new C(1)?.v; Expect.equals(1, i); } /// 03: ok
  { String s = new C(null)?.v; Expect.equals(null, s); } /// 04: static type warning

  // Let T be the static type of e1 and let y be a fresh variable of type T.
  // Exactly the same static warnings that would be caused by y.id are also
  // generated in the case of e1?.id.
  Expect.equals(null, nullC()?.bad); /// 05: static type warning
  { B b = new C(1); Expect.equals(1, b?.v); } /// 06: static type warning

  // Consequently, '?.' cannot be used to access static properties of classes.
  Expect.throws(() => C?.staticField, noMethod); /// 07: static type warning
  Expect.throws(() => h.C?.staticField, noMethod); /// 08: static type warning

  // Nor can it be used to access toplevel properties in libraries imported via
  // prefix.
  var x = h?.topLevelVar; /// 09: compile-time error

  // However, '?.' can be used to access the hashCode getter on the class Type.
  Expect.equals(C?.hashCode, (C).hashCode); /// 10: ok
  Expect.equals(h.C?.hashCode, (h.C).hashCode); /// 11: ok
}
