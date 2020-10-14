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

B? nullB() => null;
C? nullC() => null;

main() {
  var one = 1 as int?;
  var b = B('B') as B?;
  Expect.equals(1, one ?? 2);
  Expect.equals(1, one ?? null);
  Expect.equals(2, null ?? 2);
  Expect.equals(null, null ?? null);
  Expect.equals('B', (b ?? new C('C')).a);
  Expect.equals('B', ((b ?? new C('C')) as dynamic).b);
  Expect.throwsNoSuchMethodError(() => ((b ?? new C('C')) as dynamic).c);
  Expect.equals('B', (b ?? nullC())?.a);
  Expect.equals('B', ((b ?? nullC()) as dynamic).b);
  Expect.throwsNoSuchMethodError(() => ((b ?? nullC()) as dynamic).c);
  Expect.equals('C', (nullB() ?? new C('C')).a);
  Expect.throwsNoSuchMethodError(() => ((nullB() ?? new C('C')) as dynamic).b);
  Expect.equals('C', ((nullB() ?? new C('C')) as dynamic).c);
  Expect.throwsNoSuchMethodError(() => ((nullB() ?? nullC()) as dynamic).a);
  Expect.throwsNoSuchMethodError(() => ((nullB() ?? nullC()) as dynamic).b);
  Expect.throwsNoSuchMethodError(() => ((nullB() ?? nullC()) as dynamic).c);
}
