// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:math' show Random;

test2() {
  List<num> o;
  var /*@type=Iterable<num>*/ y = /*@promotedType=none*/ o
      .map(/*@returnType=num*/ (/*@type=num*/ x) {
    if (new Random().nextBool()) {
      return /*@promotedType=none*/ x.toInt() + 1;
    } else {
      return /*@promotedType=none*/ x.toDouble();
    }
  });
  Iterable<num> w = /*@promotedType=none*/ y;
  Iterable<int> z = /*info:ASSIGNMENT_CAST*/ /*@promotedType=none*/ y;
}
