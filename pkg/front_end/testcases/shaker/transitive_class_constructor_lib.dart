// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

class A1 {}

class A2 {}

class A3 {}

class A4 {}

class A5 {}

class A6 {}

class B {
  A1 publicField;
  A2 _privateField;

  B();
  B.publicConstructor(A3 a, [A4 b]);
  B._privateConstructor(A5 a);
}
