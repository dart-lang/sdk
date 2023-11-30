// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by b
// BSD-style license that can be found in the LICENSE file.

class A {
  void foo() {}
}

class B implements A {
  @override
  void foo([int i = 0]) {}
}

extension type ET1(B b) implements A {}

extension type ET2(B b) implements ET1, B {}

void main() {
  var et2 = ET2(B());
  et2.foo(42);
}