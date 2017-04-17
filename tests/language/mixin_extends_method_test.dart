// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class S {
  foo() => "S-foo";
  baz() => "S-baz";
}

class M1 {
  static m1bar() => "M1-bar";
  bar() => m1bar();
}

class M2 {
  bar() => "M2-bar";
  baz() => "M2-baz";
  fez() => "M2-fez";
}

class C extends S with M1 {}

class D extends S with M1, M2 {}

class E extends S with M2, M1 {}

class F extends E {
  fez() => "F-fez";
}

main() {
  var c = new C();
  Expect.equals("S-foo", c.foo());
  Expect.equals("M1-bar", c.bar());
  Expect.equals("S-baz", c.baz());
  Expect.throws(() => c.fez(), (error) => error is NoSuchMethodError);

  var d = new D();
  Expect.equals("S-foo", d.foo());
  Expect.equals("M2-bar", d.bar());
  Expect.equals("M2-baz", d.baz());
  Expect.equals("M2-fez", d.fez());

  var e = new E();
  Expect.equals("S-foo", e.foo());
  Expect.equals("M1-bar", e.bar());
  Expect.equals("M2-baz", e.baz());
  Expect.equals("M2-fez", e.fez());

  var f = new F();
  Expect.equals("S-foo", f.foo());
  Expect.equals("M1-bar", f.bar());
  Expect.equals("M2-baz", f.baz());
  Expect.equals("F-fez", f.fez());
}
