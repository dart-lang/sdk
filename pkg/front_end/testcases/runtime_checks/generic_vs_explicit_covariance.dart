// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

abstract class A {
  void set x(covariant Object /*@covariance=explicit*/ value);
}

class B implements A {
  void f(covariant Object /*@covariance=explicit*/ x) {}
  Object /*@covariance=explicit*/ x; // covariant
}

class C<T> implements B {
  void f(T /*@covariance=explicit, genericInterface*/ x) {}
  T /*@covariance=explicit, genericInterface*/ x;
}

main() {}
