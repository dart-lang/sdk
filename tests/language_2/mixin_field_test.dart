// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class S {
  var foo = "S-foo";
}

class M1 {
  final bar = "M1-bar";
}

class M2 {
  var baz = "M2-baz";
}

class C = S with M1;
class D = S with M1, M2;
class E = S with M2, M1;

class F extends E {
  var fez = "F-fez";
}

main() {
  dynamic c = new C();
  dynamic d = new D();
  dynamic e = new E();
  dynamic f = new F();

  Expect.equals("S-foo", c.foo);
  Expect.equals("S-foo", d.foo);
  Expect.equals("S-foo", e.foo);
  Expect.equals("S-foo", f.foo);

  Expect.equals("M1-bar", c.bar);
  Expect.equals("M1-bar", d.bar);
  Expect.equals("M1-bar", e.bar);
  Expect.equals("M1-bar", f.bar);

  Expect.throws(() => c.baz, (error) => error is NoSuchMethodError);
  Expect.equals("M2-baz", d.baz);
  Expect.equals("M2-baz", e.baz);
  Expect.equals("M2-baz", f.baz);

  Expect.throws(() => c.fez, (error) => error is NoSuchMethodError);
  Expect.throws(() => d.fez, (error) => error is NoSuchMethodError);
  Expect.throws(() => e.fez, (error) => error is NoSuchMethodError);
  Expect.equals("F-fez", f.fez);

  c.foo = "S-foo-c";
  Expect.equals("S-foo-c", c.foo);
  Expect.equals("S-foo", d.foo);
  Expect.equals("S-foo", e.foo);
  Expect.equals("S-foo", f.foo);

  d.foo = "S-foo-d";
  Expect.equals("S-foo-c", c.foo);
  Expect.equals("S-foo-d", d.foo);
  Expect.equals("S-foo", e.foo);
  Expect.equals("S-foo", f.foo);

  e.foo = "S-foo-e";
  Expect.equals("S-foo-c", c.foo);
  Expect.equals("S-foo-d", d.foo);
  Expect.equals("S-foo-e", e.foo);
  Expect.equals("S-foo", f.foo);

  f.foo = "S-foo-f";
  Expect.equals("S-foo-c", c.foo);
  Expect.equals("S-foo-d", d.foo);
  Expect.equals("S-foo-e", e.foo);
  Expect.equals("S-foo-f", f.foo);

  Expect.throws(() => c.bar = 0, (error) => error is NoSuchMethodError);
  Expect.throws(() => d.bar = 0, (error) => error is NoSuchMethodError);
  Expect.throws(() => e.bar = 0, (error) => error is NoSuchMethodError);
  Expect.throws(() => f.bar = 0, (error) => error is NoSuchMethodError);
  Expect.equals("M1-bar", c.bar);
  Expect.equals("M1-bar", d.bar);
  Expect.equals("M1-bar", e.bar);
  Expect.equals("M1-bar", f.bar);

  Expect.throws(() => c.baz = 0, (error) => error is NoSuchMethodError);
  Expect.throws(() => c.baz, (error) => error is NoSuchMethodError);
  Expect.equals("M2-baz", d.baz);
  Expect.equals("M2-baz", e.baz);
  Expect.equals("M2-baz", f.baz);

  d.baz = "M2-baz-d";
  Expect.throws(() => c.baz, (error) => error is NoSuchMethodError);
  Expect.equals("M2-baz-d", d.baz);
  Expect.equals("M2-baz", e.baz);
  Expect.equals("M2-baz", f.baz);
  Expect.equals("M2-baz", f.baz);

  e.baz = "M2-baz-e";
  Expect.throws(() => c.baz, (error) => error is NoSuchMethodError);
  Expect.equals("M2-baz-d", d.baz);
  Expect.equals("M2-baz-e", e.baz);
  Expect.equals("M2-baz", f.baz);

  f.baz = "M2-baz-f";
  Expect.throws(() => c.baz, (error) => error is NoSuchMethodError);
  Expect.equals("M2-baz-d", d.baz);
  Expect.equals("M2-baz-e", e.baz);
  Expect.equals("M2-baz-f", f.baz);

  Expect.throws(() => c.fez = 0, (error) => error is NoSuchMethodError);
  Expect.throws(() => d.fez = 0, (error) => error is NoSuchMethodError);
  Expect.throws(() => e.fez = 0, (error) => error is NoSuchMethodError);

  f.fez = "F-fez-f";
  Expect.throws(() => c.fez, (error) => error is NoSuchMethodError);
  Expect.throws(() => d.fez, (error) => error is NoSuchMethodError);
  Expect.throws(() => e.fez, (error) => error is NoSuchMethodError);
  Expect.equals("F-fez-f", f.fez);
}
