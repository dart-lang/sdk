// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

class C {
  T m<T>(int a, {String b, T c}) => null;
}

main() {
  var /*@type=double*/ y =
      new C(). /*@typeArgs=double*/ /*@target=C::m*/ m(1, b: 'bbb', c: 2.0);
}
