// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check null-shortening semantics of `?.` and `?[]`

import "package:expect/expect.dart";

import "../static_type_helper.dart";

class C1 {
  C1 get c => this;
  C1? get cq => this;
  C1? get cn => null;
  C1 get getterThrows => unreachable;
  void method(Object? v) {}
  void methodThrows() => unreachable;
  set setter(Object? v) {}
  set setterThrows(Object? v) {
    unreachable;
  }

  C1 operator [](Object? _) => this;
  operator []=(Object? _, Object? __) {}
  int n = 0;
}

extension<T> on T {
  T get id => this;
}

extension on C1 {
  C1 get extThrows => unreachable;

  // ignore: unused_element
  C1 operator +(Object? other) => unreachable;
  // ignore: unused_element
  C1 operator ~() => unreachable;
}

extension on C1? {
  C1? operator +(Object? other) => this;
  C1? operator ~() => this;
}

class C2 {
  C2? operator [](int n) => n.isEven ? this : null;
  operator []=(int n, C2? value) {}
}

main() {
  C1 c1 = C1();
  var c1q = c1 as C1?;
  C1? c1n = null;

  C2 c2 = C2();
  var c2q = c2 as C2?;

  // All selector operations short on null.
  // .foo
  // ?.foo
  // .foo=
  // ?.foo=
  // .foo()
  // ?.foo()
  // []
  // ?[]
  // []=
  // ?[]=
  // !
  // !.foo
  // ![]

  c1n?.getterThrows;
  c1n?.setterThrows = 0;
  c1n?.setter = unreachable;
  c1n?.method(unreachable);
  c1n?.methodThrows();
  c1n?[unreachable];
  c1n?[unreachable] = 0;
  c1n?[0] = unreachable;
  c1n?.extThrows;

  c1n?.c.getterThrows;
  c1n?.c.setterThrows = 0;
  c1n?.c.setter = unreachable;
  c1n?.c.method(unreachable);
  c1n?.c.methodThrows();
  c1n?.c[unreachable];
  c1n?.c[unreachable] = 0;
  c1n?.c[0] = unreachable;
  c1n?.c.extThrows;

  c1n?.cn!;
  c1n?.cn!.getterThrows;
  c1n?.cn!.setterThrows = 0;
  c1n?.cn!.setter = unreachable;
  c1n?.cn!.method(unreachable);
  c1n?.cn!.methodThrows();
  c1n?.cn![unreachable];
  c1n?.cn![unreachable] = 0;
  c1n?.cn![0] = unreachable;
  c1n?.cn!.extThrows;

  // Binary and prefix operators in general
  // do not participate in null shortening.
  var i = 0;
  c1q?.c + (i++);
  Expect.equals(i, 1);
  ~c1q?.c; // Would throw if hitting extension on C1

  // ++ and -- participates in null shortening!
  c1q?.n++;
  ++c1q?.n;
  c1n?.n++;
  ++c1n?.n;

  // Cascades do not participate in null shortening.

  c1q?.c..id.expectStaticType<Exactly<C1?>>();
  c1q?.c?..id.expectStaticType<Exactly<C1>>();

  // Null shortening works the same below cascades
  c1..cn?.getterThrows;
  c1..cn?.setterThrows = 0;
  c1..cn?.setter = unreachable;
  c1..cn?.method(unreachable);
  c1..cn?.methodThrows();
  c1..cn?[unreachable];
  c1..cn?[unreachable] = 0;
  c1..cn?[0] = unreachable;
  c1..cn?.extThrows;

  c1..cn?.c.getterThrows;
  c1..cn?.c.setterThrows = 0;
  c1..cn?.c.setter = unreachable;
  c1..cn?.c.method(unreachable);
  c1..cn?.c.methodThrows();
  c1..cn?.c[unreachable];
  c1..cn?.c[unreachable] = 0;
  c1..cn?.c[0] = unreachable;
  c1..cn?.c.extThrows;

  c1..cn?.cn!;
  c1..cn?.cn!.getterThrows;
  c1..cn?.cn!.setterThrows = 0;
  c1..cn?.cn!.setter = unreachable;
  c1..cn?.cn!.method(unreachable);
  c1..cn?.cn!.methodThrows();
  c1..cn?.cn![unreachable];
  c1..cn?.cn![unreachable] = 0;
  c1..cn?.cn![0] = unreachable;
  c1..cn?.cn!.extThrows;

  // The static types depend on whether the check is part of the
  // null shortening.
  c1q?.c.expectStaticType<Exactly<C1>>();
  (c1q?.c).expectStaticType<Exactly<C1?>>();
  c1q?.cq!.expectStaticType<Exactly<C1>>();
  (c1q?.cq!).expectStaticType<Exactly<C1?>>();
  (c1q?.cq)!.expectStaticType<Exactly<C1>>();
  c1q?.cq!.c.expectStaticType<Exactly<C1>>();
  (c1q?.cq!.c).expectStaticType<Exactly<C1?>>();
  c1q?[1].expectStaticType<Exactly<C1>>();
  (c1q?[1]).expectStaticType<Exactly<C1?>>();

  c2q?[1].expectStaticType<Exactly<C2?>>();
  (c2q?[1]).expectStaticType<Exactly<C2?>>();
}

// TODO(lrn): Change Expect.fail to return Never.
Never get unreachable => Expect.fail("Unreachable") as Never;
