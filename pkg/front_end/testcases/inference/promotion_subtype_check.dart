// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

void f(Object x) {
  if (x is int) {
    if (/*@promotedType=int*/ x is String) {
      // Promotion blocked; String is not a subtype of int.
      var /*@type=int*/ y = /*@promotedType=int*/ x;
    }
  }
}

void g(int x) {
  if (x is String) {
    // Promotion blocked; String is not a subtype of int.
    var /*@type=int*/ y = x;
  }
}

main() {}
