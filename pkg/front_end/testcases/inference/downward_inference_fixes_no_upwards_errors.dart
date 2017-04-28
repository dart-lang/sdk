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

  num a = max(
      /*@promotedType=none*/ x,
      /*info:DYNAMIC_CAST*/ /*@promotedType=none*/ y);
  Object b = max(
      /*@promotedType=none*/ x,
      /*info:DYNAMIC_CAST*/ /*@promotedType=none*/ y);
  dynamic c = /*error:COULD_NOT_INFER*/ max(
      /*@promotedType=none*/ x,
      /*@promotedType=none*/ y);
  var /*@type=dynamic*/ d = /*error:COULD_NOT_INFER*/ max(
      /*@promotedType=none*/ x,
      /*@promotedType=none*/ y);
}
