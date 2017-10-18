// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Evaluation of an if-null expression e of the form e1 ?? e2 is equivalent to
// the evaluation of the expression ((x) => x == null ? e2 : x)(e1).  The
// static type of e is the least upper bound of the static type of e1 and the
// static type of e2.

import "package:expect/expect.dart";

class A {
  final String a;
  A(this.a);
}

class B extends A {
  B(String v)
      : b = v,
        super(v);
  final String b;
}

class C extends A {
  C(String v)
      : c = v,
        super(v);
  final String c;
}

B nullB() => null;
C nullC() => null;

noMethod(e) => e is NoSuchMethodError;

main() {
  // Make sure the "none" test fails if "??" is not implemented.  This makes
  // status files easier to maintain.
  var _ = null ?? null;

  Expect.equals(1, 1 ?? 2); //# 01: ok
  Expect.equals(1, 1 ?? null); //# 02: ok
  Expect.equals(2, null ?? 2); //# 03: ok
  Expect.equals(null, null ?? null); //# 04: ok
  Expect.equals('B', (new B('B') ?? new C('C')).a); //# 05: ok
  Expect.equals('B', (new B('B') ?? new C('C')).b); //# 06: static type warning
  Expect.throws(() => (new B('B') ?? new C('C')).c, noMethod); //# 07: static type warning
  Expect.equals('B', (new B('B') ?? nullC()).a); //# 08: ok
  Expect.equals('B', (new B('B') ?? nullC()).b); //# 09: static type warning
  Expect.throws(() => (new B('B') ?? nullC()).c, noMethod); //# 10: static type warning
  Expect.equals('C', (nullB() ?? new C('C')).a); //# 11: ok
  Expect.throws(() => (nullB() ?? new C('C')).b, noMethod); //# 12: static type warning
  Expect.equals('C', (nullB() ?? new C('C')).c); //# 13: static type warning
  Expect.throws(() => (nullB() ?? nullC()).a, noMethod); //# 14: ok
  Expect.throws(() => (nullB() ?? nullC()).b, noMethod); //# 15: static type warning
  Expect.throws(() => (nullB() ?? nullC()).c, noMethod); //# 16: static type warning
}
