// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test;

import 'dart:async';

abstract class MyFuture implements Future<int> {}

void test(
  int x0,
  Future<int> x1,
  Future<Future<int>> x2,
  Future<FutureOr<int>> x3,
  Future<MyFuture> x4,
  FutureOr<int> x5,
  FutureOr<Future<int>> x6,
  FutureOr<FutureOr<int>> x7,
  FutureOr<MyFuture> x8,
  MyFuture x9,
) async {
  test0() async => x0;
  test1() async => x1;
  test2() async => x2;
  test3() async => x3;
  test4() async => x4;
  test5() async => x5;
  test6() async => x6;
  test7() async => x7;
  test8() async => x8;
  test9() async => x9;

  var y0 = await x0;
  var y1 = await x1;
  var y2 = await x2;
  var y3 = await x3;
  var y4 = await x4;
  var y5 = await x5;
  var y6 = await x6;
  var y7 = await x7;
  var y8 = await x8;
  var y9 = await x9;
}

main() {}
