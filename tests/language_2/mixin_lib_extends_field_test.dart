// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mixin_lib_extends_field_test;

import 'package:expect/expect.dart';
import "mixin_lib_extends_field_lib.dart" as L;

class S {
  var foo = "S-foo";
}

class C extends S with L.M1 {}

class D extends S with L.M1, L.M2 {}

class E extends S with L.M2, L.M1 {}

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

  Expect.throwsNoSuchMethodError(() => c.baz);
  Expect.equals("M2-baz", d.baz);
  Expect.equals("M2-baz", e.baz);
  Expect.equals("M2-baz", f.baz);

  Expect.throwsNoSuchMethodError(() => c.fez);
  Expect.throwsNoSuchMethodError(() => d.fez);
  Expect.throwsNoSuchMethodError(() => e.fez);
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

  Expect.throwsNoSuchMethodError(() => c.bar = 0);
  Expect.throwsNoSuchMethodError(() => d.bar = 0);
  Expect.throwsNoSuchMethodError(() => e.bar = 0);
  Expect.throwsNoSuchMethodError(() => f.bar = 0);
  Expect.equals("M1-bar", c.bar);
  Expect.equals("M1-bar", d.bar);
  Expect.equals("M1-bar", e.bar);
  Expect.equals("M1-bar", f.bar);

  Expect.throwsNoSuchMethodError(() => c.baz = 0);
  Expect.throwsNoSuchMethodError(() => c.baz);
  Expect.equals("M2-baz", d.baz);
  Expect.equals("M2-baz", e.baz);
  Expect.equals("M2-baz", f.baz);

  d.baz = "M2-baz-d";
  Expect.throwsNoSuchMethodError(() => c.baz);
  Expect.equals("M2-baz-d", d.baz);
  Expect.equals("M2-baz", e.baz);
  Expect.equals("M2-baz", f.baz);
  Expect.equals("M2-baz", f.baz);

  e.baz = "M2-baz-e";
  Expect.throwsNoSuchMethodError(() => c.baz);
  Expect.equals("M2-baz-d", d.baz);
  Expect.equals("M2-baz-e", e.baz);
  Expect.equals("M2-baz", f.baz);

  f.baz = "M2-baz-f";
  Expect.throwsNoSuchMethodError(() => c.baz);
  Expect.equals("M2-baz-d", d.baz);
  Expect.equals("M2-baz-e", e.baz);
  Expect.equals("M2-baz-f", f.baz);

  Expect.throwsNoSuchMethodError(() => c.fez = 0);
  Expect.throwsNoSuchMethodError(() => d.fez = 0);
  Expect.throwsNoSuchMethodError(() => e.fez = 0);

  f.fez = "F-fez-f";
  Expect.throwsNoSuchMethodError(() => c.fez);
  Expect.throwsNoSuchMethodError(() => d.fez);
  Expect.throwsNoSuchMethodError(() => e.fez);
  Expect.equals("F-fez-f", f.fez);
}
