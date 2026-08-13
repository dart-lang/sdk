// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class D1 {}

class D2 {}

class D implements D1, D2 {}

class A {
  void m(covariant D d) {}
}

abstract class B1 {
  void m(D1 d1);
}

abstract class B2 {
  void m(D2 d2);
}

main() {}
