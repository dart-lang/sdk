// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
}

class B implements A {
  @override
  bool operator ==(covariant A other) {
    return true;
  }
}

class C {}

extension type ET1(B b) implements A {}

extension type ET2(B b) implements ET1, B {}

void test() {
  var e2 = ET2(B());
  ET1 e1 = e2;
  e2 == A();
  e2 == B();
  e2 == Object();
  e2 == C();

  e1 == A();
  e1 == B();
  e1 == Object();
  e1 == C();
}
