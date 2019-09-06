// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*@testedFeatures=inference*/
library test;

import 'dart:async';

abstract class MyFuture implements Future<int> {}

void test() async {
  int x0;
  Future<int> x1;
  Future<Future<int>> x2;
  Future<FutureOr<int>> x3;
  Future<MyFuture> x4;
  FutureOr<int> x5;
  FutureOr<Future<int>> x6;
  FutureOr<FutureOr<int>> x7;
  FutureOr<MyFuture> x8;
  MyFuture x9;

  /*@ returnType=Future<int*>* */ test0() async => x0;
  /*@ returnType=Future<int*>* */ test1() async => x1;
  /*@ returnType=Future<Future<int*>*>* */ test2() async => x2;
  /*@ returnType=Future<FutureOr<int*>*>* */ test3() async => x3;
  /*@ returnType=Future<MyFuture*>* */ test4() async => x4;
  /*@ returnType=Future<int*>* */ test5() async => x5;
  /*@ returnType=Future<Future<int*>*>* */ test6() async => x6;
  /*@ returnType=Future<FutureOr<int*>*>* */ test7() async => x7;
  /*@ returnType=Future<MyFuture*>* */ test8() async => x8;
  /*@ returnType=Future<int*>* */ test9() async => x9;

  var /*@ type=int* */ y0 = await x0;
  var /*@ type=int* */ y1 = await x1;
  var /*@ type=Future<int*>* */ y2 = await x2;
  var /*@ type=FutureOr<int*>* */ y3 = await x3;
  var /*@ type=MyFuture* */ y4 = await x4;
  var /*@ type=int* */ y5 = await x5;
  var /*@ type=Future<int*>* */ y6 = await x6;
  var /*@ type=FutureOr<int*>* */ y7 = await x7;
  var /*@ type=MyFuture* */ y8 = await x8;
  var /*@ type=int* */ y9 = await x9;
}

main() {}
