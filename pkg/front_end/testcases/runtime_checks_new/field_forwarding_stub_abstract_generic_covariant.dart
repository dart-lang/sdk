// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

class B<T> {
  T /*@covariance=genericInterface, genericImpl*/ x;
}

class /*@forwardingStub=abstract void set x(covariance=(genericImpl) num _)*/ C
    extends B<num> {}

void main() {}
