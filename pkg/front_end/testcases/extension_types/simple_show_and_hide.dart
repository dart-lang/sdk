// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class I1<X, Y> {}

class I2<X, Y, Z> {}

class A {}

class B extends A implements I1<int, int> {
  void methodB() {}
  void methodB2() {}
  int get getterB => throw 42;
  void set setterB(int value) {}
  B operator *(B other) => throw 42;
}

class C extends B {}

class D extends C implements I2<int, int, int> {
  void methodD() {}
  int get getterD => throw 42;
  void set setterD(int value) {}
  D operator +(D other) => throw 42;
}

extension type E on D
  show C, I2<int, int, int>, methodD, get getterD, set setterD, operator +
  hide A, I1<int, int>, methodB, methodB2, get getterB, set setterB, operator *
  {}

main() {}
