// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

class B<T> {
  T /*@covariance=genericInterface, genericImpl*/ x;
}

class C {
  num x;
}

class /*@forwardingStub=void set x(covariance=(genericImpl) num _)*/ D extends C
    implements B<num> {}

void main() {}
