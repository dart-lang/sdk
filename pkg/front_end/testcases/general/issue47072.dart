// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class A {}

class B extends A {}

class C {
  // The parameter `b` is not covariant-by-declaration as seen from here.
  void f(B b) {}
}

abstract class I {
  // If `I` is a superinterface of any class,
  // the parameter of its `f` is covariant-by-declaration.
  void f(covariant A a);
}

class D extends C implements I {} // OK.

void main() {
  I i = D();
  try {
    i.f(A()); // Dynamic type error.
  } catch (_) {
    return;
  }
  throw 'Missing type error';
}
