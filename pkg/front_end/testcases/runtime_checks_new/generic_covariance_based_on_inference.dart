// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=checks*/
library test;

class B<T> {
  T x;
  T y;
}

// This class inherits genericImpl annotations from its superclass, but doesn't
// have any members marked genericInterface because the inferred types of x and
// y do not depend on the type parameter T.
abstract class C<T> implements B<num> {
  var x;
  get y;
  set y(value);
}

// This class also has members marked genericInterface, since the inferred types
// of x and y *do* depend on the type parameter T.
abstract class D<T> implements B<T> {
  var x;
  get y;
  set y(value);
}

main() {}
