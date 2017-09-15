// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

class C<T> {
  void set x(T /*@covariance=genericInterface, genericImpl*/ t) {}
  T /*@covariance=genericInterface, genericImpl*/ y;
}

class D implements C<num> {
  num /*@covariance=genericImpl*/ x;
  num /*@covariance=genericImpl*/ y;
}

class E implements C<num> {
  void set x(num /*@covariance=genericImpl*/ t) {}
  num get y => null;
  void set y(num /*@covariance=genericImpl*/ t) {}
}

void main() {}
