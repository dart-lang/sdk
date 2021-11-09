// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the treatment of a method whose signature has a covariant parameter
// in the interface of a class `C`, when the implementation of that method
// is inherited and its parameter is not covariant.

class I0 {}

class A {}

class B extends A implements I0 {}

class C {
  void f(B x) {}
}

abstract class I {
  void f(covariant A x);
}

// As of dart-lang/language#1833 this is not a compile-time.
class D extends C implements I {}

main() {}
