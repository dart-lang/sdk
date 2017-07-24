// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// VMOptions=--optimization_counter_threshold=5
//
// Basic null-aware operator test that invokes the optimizing compiler.

import "package:expect/expect.dart";

class C {
  C(this.f);
  var f;
  m(a) => a;
}

bomb() {
  Expect.fail('Should not be executed');
  return 100;
}

getNull() => null;

test() {
  var c;
  var d = new C(5);
  Expect.equals(null, c?.m(bomb()));
  Expect.equals(null, getNull()?.anything(bomb()));
  Expect.equals(1, d?.m(1));

  Expect.equals(1, new C(1)?.f);
  Expect.equals(null, c?.v);
  Expect.equals(10, c ?? 10);
  Expect.equals(d, d ?? bomb());
  Expect.equals(
      3,
      [
        [3]
      ]?.expand((i) => i).toList()[0]);
  Expect.equals(null, (null as List<List<int>>)?.expand((i) => i)?.toList());

  var e;
  // The assignment to e is not executed since d != null.
  d ??= e ??= new C(100);
  Expect.equals(null, e);
  e ??= new C(100);
  Expect.equals(100, e?.f);
  e?.f ??= 200;
  Expect.equals(100, e?.f);

  e.f = null;
  e?.f ??= 200;
  Expect.equals(200, e?.f);

  c?.f ??= 400;
  Expect.equals(null, c?.f);
  Expect.equals(null, c?.f++);
  e?.f++;
  Expect.equals(201, e.f);

  var x = 5 ?? bomb();
}

// Check that instructions without result do not crash.
test2() {
  var c;
  c?.v;
  c?.m(bomb());
}

class Bar {
  String s;
}

class Foo {
  Bar _bar;
  String str;

  Foo(this._bar) : str = _bar?.s;
}

main() {
  for (int i = 0; i < 10; i++) {
    test();
    test2();
  }

  Expect.equals(null, new Foo(new Bar()).str);
}
