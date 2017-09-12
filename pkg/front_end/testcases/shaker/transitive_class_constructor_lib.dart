// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class A1 {}

class A2 {}

class A3 {}

class A4 {}

class A5 {}

class A6 {}

class S1 {
  S1();
  S1.namedConstructor1();
  S1.namedConstructor2();
}

class S2 extends S1 {
  S2();
  S2.namedConstructor1() : super.namedConstructor1();
  S2.namedConstructor2() : super.namedConstructor2();
}

class B extends S2 {
  A1 publicField;
  A2 _privateField;

  B();
  B.publicConstructor(A3 a, [A4 b]) : super.namedConstructor1();
  B._privateConstructor(A5 a);
}
