// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

class B {
  void f(covariant int /*@covariance=explicit*/ x, int y) {}
}

abstract class I {
  void f(int x, Object y);
}

class
/*@forwardingStub=void f(covariance=(explicit) int x, covariance=() Object y)*/
    C extends B implements I {}

void main() {}
