// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

test() {
  f0() => 42;
  f1() async => 42;

  f2() {
    return 42;
  }

  f3() async {
    return 42;
  }

  f4() sync* {
    yield 42;
  }

  f5() async* {
    yield 42;
  }

  num f6() => 42;

  f7() => f7();
  f8() => /*error:REFERENCED_BEFORE_DECLARATION*/ f9();
  f9() => f5();

  var /*@type=() -> int*/ v0 = f0;
  var /*@type=() -> Future<int>*/ v1 = f1;
  var /*@type=() -> int*/ v2 = f2;
  var /*@type=() -> Future<int>*/ v3 = f3;
  var /*@type=() -> Iterable<int>*/ v4 = f4;
  var /*@type=() -> Stream<int>*/ v5 = f5;
  var /*@type=() -> num*/ v6 = f6;
  var /*@type=() -> dynamic*/ v7 = f7;
  var /*@type=() -> dynamic*/ v8 = f8;
  var /*@type=() -> Stream<int>*/ v9 = f9;
}

main() {}
