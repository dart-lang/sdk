// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

main() {
  Future<int> base;
  var /*@type=Future<bool>*/ f =
      base. /*@typeArgs=bool*/ /*@target=Future::then*/ then(
          /*@returnType=bool*/ (/*@type=int*/ x) {
    return x /*@target=num::==*/ == 0;
  });
  var /*@type=Future<bool>*/ g =
      base. /*@typeArgs=bool*/ /*@target=Future::then*/ then(
          /*@returnType=bool*/ (/*@type=int*/ x) => x /*@target=num::==*/ == 0);
  Future<bool> b = f;
  b = g;
}
