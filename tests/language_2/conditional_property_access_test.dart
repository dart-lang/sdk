// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify semantics of the ?. operator when it does not appear on the LHS of an
// assignment.

import "package:expect/expect.dart";
import "conditional_access_helper.dart" as h;

class B {}

class C extends B {
  int v;
  C(this.v);
  static int staticInt;
}

C nullC() => null;

main() {
  // Make sure the "none" test fails if property access using "?." is not
  // implemented.  This makes status files easier to maintain.
  nullC()?.v;

  // e1?.id is equivalent to ((x) => x == null ? null : x.id)(e1).
  Expect.equals(null, nullC()?.v); //# 01: ok
  Expect.equals(1, new C(1)?.v); //# 02: ok

  // C?.id is equivalent to C.id.
  { C.staticInt = 1; Expect.equals(1, C?.staticInt); } //# 12: ok
  { h.C.staticInt = 1; Expect.equals(1, h.C?.staticInt); } //# 13: ok

  // The static type of e1?.d is the static type of e1.id.
  { int i = new C(1)?.v; Expect.equals(1, i); } //# 03: ok
  { String s = new C(null)?.v; Expect.equals(null, s); } //# 04: compile-time error
  { C.staticInt = 1; int i = C?.staticInt; Expect.equals(1, i); } //# 14: ok
  { h.C.staticInt = 1; int i = h.C?.staticInt; Expect.equals(1, i); } //# 15: ok
  { C.staticInt = null; String s = C?.staticInt; Expect.equals(null, s); } //# 16: compile-time error
  { h.C.staticInt = null; String s = h.C?.staticInt; Expect.equals(null, s); } //# 17: compile-time error

  // Let T be the static type of e1 and let y be a fresh variable of type T.
  // Exactly the same static warnings that would be caused by y.id are also
  // generated in the case of e1?.id.
  Expect.equals(null, nullC()?.bad); //# 05: compile-time error
  { B b = new C(1); Expect.equals(1, b?.v); } //# 06: compile-time error

  // '?.' cannot be used to access toplevel properties in libraries imported via
  // prefix.
  var x = h?.topLevelVar; //# 09: compile-time error

  // Nor can it be used to access the hashCode getter on the class Type.
  Expect.throwsNoSuchMethodError(() => C?.hashCode); //# 10: compile-time error
  Expect.throwsNoSuchMethodError(() => h.C?.hashCode); //# 11: compile-time error
}
