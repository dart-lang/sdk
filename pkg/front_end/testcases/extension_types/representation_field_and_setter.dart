// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension type A(int property) {
  void set property(int value) {}
}

extension type B1(int it) {
  void set property(int value) {}
}

extension type B2(int property) implements B1 {}

extension type C1(int property) {}

extension type C2(int it) implements C1 {
  void set property(int value) {}
}

class D1 {
  void set property(D1 value) {}
}

extension type D2(D1 property) implements D1 {}

main() {
  A a = A(0);
  a.property = a.property;

  B2 b = B2(0);
  b.property = b.property;

  C2 c = C2(0);
  c.property = c.property;

  D2 d = D2(D1());
  d.property = d.property;
}
