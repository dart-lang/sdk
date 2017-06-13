// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';
import 'dart:math' show Random;

main() {
  var /*@type=() -> Future<num>*/ f = /*@returnType=Future<num>*/ () async {
    if (new Random(). /*@target=dart.math::Random::nextBool*/ nextBool()) {
      return new Future<int>.value(1);
    } else {
      return new Future<double>.value(2.0);
    }
  };
  Future<num> g = f();
  Future<int> h = /*info:ASSIGNMENT_CAST*/ f();
}
