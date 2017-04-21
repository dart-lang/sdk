// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class S {}

class M1 {}

class M2 {}

class C extends S with M1 {}

class D extends S with M1, M2 {}

class E extends S with M2, M1 {}

class F extends E {}

class C_ extends S with M1 {}

class D_ extends S with M1, M2 {}

class E_ extends S with M2, M1 {}

class F_ extends E_ {}

main() {
  var c = new C();
  Expect.isTrue(c is C);
  Expect.isFalse(c is D);
  Expect.isFalse(c is E);
  Expect.isFalse(c is F);
  Expect.isTrue(c is S);
  Expect.isTrue(c is M1);
  Expect.isFalse(c is M2);

  var d = new D();
  Expect.isFalse(d is C);
  Expect.isTrue(d is D);
  Expect.isFalse(d is E);
  Expect.isFalse(d is F);
  Expect.isTrue(d is S);
  Expect.isTrue(d is M1);
  Expect.isTrue(d is M2);

  var e = new E();
  Expect.isFalse(e is C);
  Expect.isFalse(e is D);
  Expect.isTrue(e is E);
  Expect.isFalse(e is F);
  Expect.isTrue(e is S);
  Expect.isTrue(e is M1);
  Expect.isTrue(e is M2);

  var f = new F();
  Expect.isFalse(f is C);
  Expect.isFalse(f is D);
  Expect.isTrue(f is E);
  Expect.isTrue(f is F);
  Expect.isTrue(f is S);
  Expect.isTrue(f is M1);
  Expect.isTrue(f is M2);

  // Make sure we get a new class for each mixin
  // application (at least the named ones).
  Expect.isFalse(c is C_);
  Expect.isFalse(c is D_);
  Expect.isFalse(c is E_);
  Expect.isFalse(c is F_);

  Expect.isFalse(d is C_);
  Expect.isFalse(d is D_);
  Expect.isFalse(d is E_);
  Expect.isFalse(d is F_);

  Expect.isFalse(e is C_);
  Expect.isFalse(e is D_);
  Expect.isFalse(e is E_);
  Expect.isFalse(e is F_);

  Expect.isFalse(f is C_);
  Expect.isFalse(f is D_);
  Expect.isFalse(f is E_);
  Expect.isFalse(f is F_);
}
