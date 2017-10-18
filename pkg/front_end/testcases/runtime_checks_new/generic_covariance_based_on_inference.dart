// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

class B<T> {
  T /*@covariance=genericInterface, genericImpl*/ x;
  T /*@covariance=genericInterface, genericImpl*/ y;
}

// This class inherits genericImpl annotations from its superclass, but doesn't
// have any members marked genericInterface because the inferred types of x and
// y do not depend on the type parameter T.
class C<T> implements B<num> {
  var /*@covariance=genericImpl*/ x;
  get y;
  set y(/*@covariance=genericImpl*/ value);
}

// This class also has members marked genericInterface, since the inferred types
// of x and y *do* depend on the type parameter T.
class D<T> implements B<T> {
  var /*@covariance=genericInterface, genericImpl*/ x;
  get y;
  set y(/*@covariance=genericInterface, genericImpl*/ value);
}

main() {}
