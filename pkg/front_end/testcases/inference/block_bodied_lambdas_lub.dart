// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:math' show Random;

test2() {
  List<num> o;
  var /*@type=Iterable<num>*/ y =
      o. /*@typeArgs=num*/ /*@target=Iterable::map*/ map(
          /*@returnType=num*/ (/*@type=num*/ x) {
    if (new Random(). /*@target=dart.math::Random::nextBool*/ nextBool()) {
      return x. /*@target=num::toInt*/ toInt() /*@target=num::+*/ + 1;
    } else {
      return x. /*@target=num::toDouble*/ toDouble();
    }
  });
  Iterable<num> w = y;
  Iterable<int> z = /*info:ASSIGNMENT_CAST*/ y;
}

main() {}
