// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

class B {
  covariant num /*@covariance=explicit*/ x;
}

class C {
  int x;
}

class /*@forwardingStub=abstract void set x(covariance=(explicit) num _)*/ D
    extends C implements B {}

void main() {}
