// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mixin_lib_extends_method_test;

import "package:expect/expect.dart";
import "mixin_lib_extends_method_lib.dart" as L;

class S {
  foo() => "S-foo";
  baz() => "S-baz";
}

class C extends S with L.M1 {}

class D extends S with L.M1, L.M2 {}

class E extends S with L.M2, L.M1 {}

class F extends E {
  fez() => "F-fez";
}

main() {
  var c = new C();
  Expect.equals("S-foo", c.foo());
  Expect.equals("M1-bar", c.bar());
  Expect.equals("S-baz", c.baz());
  Expect.throws(() => c.fez(), (error) => error is NoSuchMethodError);
  Expect.equals("sugus", c.clo("su")("gus"));

  var d = new D();
  Expect.equals("S-foo", d.foo());
  Expect.equals("M2-bar", d.bar());
  Expect.equals("M2-baz", d.baz());
  Expect.equals("M2-fez", d.fez());
  Expect.equals("sugus", d.clo("su")("gus"));

  var e = new E();
  Expect.equals("S-foo", e.foo());
  Expect.equals("M1-bar", e.bar());
  Expect.equals("M2-baz", e.baz());
  Expect.equals("M2-fez", e.fez());
  Expect.equals("sugus", e.clo("su")("gus"));

  var f = new F();
  Expect.equals("S-foo", f.foo());
  Expect.equals("M1-bar", f.bar());
  Expect.equals("M2-baz", f.baz());
  Expect.equals("F-fez", f.fez());
  Expect.equals("sugus", f.clo("su")("gus"));
}
