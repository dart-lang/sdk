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

main() {
  Expect.equals(1, 1 ?? 2);
  Expect.equals(1, 1 ?? null);
  Expect.equals(2, null ?? 2);
  Expect.equals(null, null ?? null);
  Expect.equals('B', (new B('B') ?? new C('C')).a);
  Expect.equals('B', ((new B('B') ?? new C('C')) as dynamic).b);
  Expect.throwsNoSuchMethodError(() => ((new B('B') ?? new C('C')) as dynamic).c);
  Expect.equals('B', (new B('B') ?? nullC()).a);
  Expect.equals('B', ((new B('B') ?? nullC()) as dynamic).b);
  Expect.throwsNoSuchMethodError(() => ((new B('B') ?? nullC()) as dynamic).c);
  Expect.equals('C', (nullB() ?? new C('C')).a);
  Expect.throwsNoSuchMethodError(() => ((nullB() ?? new C('C')) as dynamic).b);
  Expect.equals('C', ((nullB() ?? new C('C')) as dynamic).c);
  Expect.throwsNoSuchMethodError(() => (nullB() ?? nullC()).a);
  Expect.throwsNoSuchMethodError(() => ((nullB() ?? nullC()) as dynamic).b);
  Expect.throwsNoSuchMethodError(() => ((nullB() ?? nullC()) as dynamic).c);
}
