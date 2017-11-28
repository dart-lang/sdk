// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

test() {
  var /*@type=() -> Iterable<num>*/ f = /*@returnType=Iterable<num>*/ () sync* {
    yield 1;
    yield* /*@typeArgs=num*/ [3, 4.0];
  };
  Iterable<num> g = f();
  Iterable<int> h = /*info:ASSIGNMENT_CAST*/ f();
}

main() {}
