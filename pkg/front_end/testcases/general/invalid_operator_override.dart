// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A operator +(A a) => a;
  B operator -() => new B();
  B operator [](A a) => new B();
  void operator []=(A a1, A a2) {}
}

class B extends A {
  A operator +(B b) => b;
  A operator -() => this;
  B operator [](B b) => b;
  void operator []=(B b, A a) {}
}

class C extends A {
  A operator [](B b) => b;
  void operator []=(A a, B b) {}
}

main() {}
