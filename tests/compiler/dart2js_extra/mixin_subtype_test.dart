// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

class A {}

class B {}

class I {}

class J {}

mixin M1 on A, B implements I, J {}

class M2 implements A, B, I, J {}

class M3 implements A, B, I, J {}

class M4 implements A, B, I, J {}

class M5 implements A, B, I, J {}

class C implements A, B {}

class D1 = C with M1;

class D2 = C with M2;

class D3 = C with M3;

class D4 extends C with M4 {}

class D5 extends C with M5 {}

class E5 extends D5 {}

@pragma('dart2js:noInline')
test(o) {}

main() {
  test(new M3());
  test(new D2());
  test(new D4());
  test(new E5());
  Expect.subtype<D1, M1>();
  Expect.subtype<D2, M2>();
  Expect.subtype<D3, M3>();
  Expect.subtype<D4, M4>();
  Expect.subtype<D5, M5>();
  Expect.subtype<E5, M5>();
}
