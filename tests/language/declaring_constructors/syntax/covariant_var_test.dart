// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Allow the modifier `covariant` in declaring parameters.

// SharedOptions=--enable-experiment=declaring-constructors

import 'package:expect/expect.dart';

class A {}
class B extends A {}

class C1(covariant var A x);
class D1(var B x) implements C1;

class C2({covariant var A? x});
class D2({var B? x}) implements C2;

class C3({required covariant var A x});
class D3({required var B x}) implements C2;

class C4([covariant var A? x]);
class D4([var B? x]) implements C2;

class C5 {
  this(covariant var A x);
}
class D5 implements C5 {
  this(var B x);
}

class C6 {
  this({covariant var A? x});
}
class D6 {
  this({var B? x});
}

class C7 {
  this({required covariant var A x});
}
class D7 {
  this({required var B x});
}

class C8 {
  this([covariant var A? x]);
}
class D8 {
  this([var B? x]);
}

void main() {
  A a = A();
  B b = B();

  // In-header
  Expect.equals(a, C1(a).x);
  Expect.equals(b, D1(b).x);

  Expect.equals(a, C2(x: a).x);
  Expect.equals(b, D2(x: b).x);

  Expect.equals(a, C3(x: a).x);
  Expect.equals(b, D3(x: b).x);

  Expect.equals(a, C4(a).x);
  Expect.equals(b, D4(b).x);

  // In-body
  Expect.equals(a, C5(a).x);
  Expect.equals(b, D5(b).x);

  Expect.equals(a, C6(x: a).x);
  Expect.equals(b, D6(x: b).x);

  Expect.equals(a, C7(x: a).x);
  Expect.equals(b, D7(x: b).x);

  Expect.equals(a, C8(a).x);
  Expect.equals(b, D8(b).x);
}
