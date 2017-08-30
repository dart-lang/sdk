// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class A1 {}

class A2 {}

class A3 {}

class A4 {}

class A5 {}

class A6 {}

class A7 {}

class A8 {}

class A9 {}

class B {
  A1 publicField;
  A2 _privateField;
}

class C {
  A3 publicField;
  A4 _privateField;
  B b;

  C();
  C.named();

  void publicMethod(A5 a) {}
  void _privateMethod(A6 a) {}
}
