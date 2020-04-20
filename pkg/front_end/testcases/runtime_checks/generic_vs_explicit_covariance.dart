// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

abstract class A {
  void set x(covariant Object value);
}

class B implements A {
  void f(covariant Object x) {}
  Object x; // covariant
}

class C<T> implements B {
  void f(T x) {}
  T x;
}

main() {}
