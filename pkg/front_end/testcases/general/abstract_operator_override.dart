// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {
  A operator +(B b) => new A();
  A operator -() => new A();
  A operator [](B b) => new A();
  void operator []=(B b1, B b2) {}
}

class B extends A {
  A operator +(A a);
  B operator -();
  A operator [](A a);
  void operator []=(A a, B b);
}

class C extends A {
  B operator [](B b);
  void operator []=(B b, A a);
}

main() {}
