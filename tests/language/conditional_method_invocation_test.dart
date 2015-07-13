// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Verify semantics of the ?. operator when it is used to invoke a method.

import "package:expect/expect.dart";
import "conditional_access_helper.dart" as h;

bad() {
  Expect.fail('Should not be executed');
}

noMethod(e) => e is NoSuchMethodError;

class B {}

class C extends B {
  f(callback()) => callback();
  int g(int callback()) => callback();
  static void staticMethod() {}
}

C nullC() => null;

main() {
  // Make sure the "none" test fails if method invocation using "?." is not
  // implemented.  This makes status files easier to maintain.
  nullC()?.f(null);

  // o?.m(...) is equivalent to ((x) => x == null ? null : x.m(...))(o).
  Expect.equals(null, nullC()?.f(bad())); /// 01: ok
  Expect.equals(1, new C()?.f(() => 1)); /// 02: ok

  // The static type of o?.m(...) is the same as the static type of
  // o.m(...).
  { int i = nullC()?.g(bad()); Expect.equals(null, i); } /// 03: ok
  { int i = new C()?.g(() => 1); Expect.equals(1, i); } /// 04: ok
  { String s = nullC()?.g(bad()); Expect.equals(null, s); } /// 05: static type warning
  { String s = new C()?.g(() => null); Expect.equals(null, s); } /// 06: static type warning

  // Let T be the static type of o and let y be a fresh variable of type T.
  // Exactly the same static warnings that would be caused by y.m(...) are also
  // generated in the case of o?.m(...).
  { B b = new C(); Expect.equals(1, b?.f(() => 1)); } /// 07: static type warning
  { int i = 1; Expect.equals(null, nullC()?.f(i)); } /// 08: static type warning

  // Consequently, '?.' cannot be used to invoke static methods of classes.
  Expect.throws(() => C?.staticMethod(), noMethod); /// 09: static type warning
  Expect.throws(() => h.C?.staticMethod(), noMethod); /// 10: static type warning

  // Nor can it be used to access toplevel functions in libraries imported via
  // prefix.
  h?.topLevelFunction(); /// 11: compile-time error

  // However, '?.' can be used to access the toString method on the class Type.
  Expect.equals(C?.toString(), (C).toString()); /// 12: ok
  Expect.equals(h.C?.toString(), (h.C).toString()); /// 13: ok
}
