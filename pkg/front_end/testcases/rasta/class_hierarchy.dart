// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A extends Missing {}

class B implements Missing {}

class C = Object with Missing;

class D {
  factory D() = Missing;
}

void main() {
  new A();
  new B();
  new C();
  new D();
}
