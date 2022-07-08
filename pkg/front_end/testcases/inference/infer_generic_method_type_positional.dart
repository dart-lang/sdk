// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C {
  T m<T>(int a, [T? b]) => throw '';
}

test() {
  var /*@type=double*/ y =
      new C(). /*@typeArgs=double*/ /*@target=C.m*/ m(1, 2.0);
}
