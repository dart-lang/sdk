// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

test() {
  /*@returnType=int*/ f0() => 42;
  /*@returnType=Future<int>*/ f1() async => 42;

  /*@returnType=int*/ f2() {
    return 42;
  }

  /*@returnType=Future<int>*/ f3() async {
    return 42;
  }

  /*@returnType=Iterable<int>*/ f4() sync* {
    yield 42;
  }

  /*@returnType=Stream<int>*/ f5() async* {
    yield 42;
  }

  num f6() => 42;

  /*@returnType=dynamic*/ f7() => f7();
  /*@returnType=Stream<int>*/ f8() => f5();

  var /*@type=() -> int*/ v0 = f0;
  var /*@type=() -> Future<int>*/ v1 = f1;
  var /*@type=() -> int*/ v2 = f2;
  var /*@type=() -> Future<int>*/ v3 = f3;
  var /*@type=() -> Iterable<int>*/ v4 = f4;
  var /*@type=() -> Stream<int>*/ v5 = f5;
  var /*@type=() -> num*/ v6 = f6;
  var /*@type=() -> dynamic*/ v7 = f7;
  var /*@type=() -> Stream<int>*/ v8 = f8;
}

main() {}
