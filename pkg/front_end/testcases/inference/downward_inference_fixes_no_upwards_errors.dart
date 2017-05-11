// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:math';

// T max<T extends num>(T x, T y);
main() {
  num x;
  dynamic y;

  num a = /*@typeArgs=num*/ max(
      x,
      /*info:DYNAMIC_CAST*/ y);
  Object b = /*@typeArgs=num*/ max(
      x,
      /*info:DYNAMIC_CAST*/ y);
  dynamic c = /*error:COULD_NOT_INFER*/ /*@typeArgs=dynamic*/ max(x, y);
  var /*@type=dynamic*/ d = /*error:COULD_NOT_INFER*/ /*@typeArgs=dynamic*/ max(
      x, y);
}
