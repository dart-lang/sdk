// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class A {
  int x = 2;
}

test() {
  var /*@type=A*/ a = new A();
  A b = a; // doesn't require down cast
  print(a.x); // doesn't require dynamic invoke
  print(a.x /*@target=num::+*/ + 2); // ok to use in bigger expression
}
