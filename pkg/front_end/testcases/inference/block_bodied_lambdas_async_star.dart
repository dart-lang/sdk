// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

test() {
  var /*@type=() -> Stream<num>*/ f = /*@returnType=Stream<num>*/ () async* {
    yield 1;
    Stream<double> s;
    yield* s;
  };
  Stream<num> g = f();
  Stream<int> h = /*info:ASSIGNMENT_CAST*/ f();
}

main() {}
