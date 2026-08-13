// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:developer';

import 'common/test_helper.dart';

class A {}

class B extends A {}

class C extends Object with ListMixin<C> implements List<C> {
  @override
  int length = 0;
  @override
  C operator [](int index) => throw UnimplementedError();
  @override
  void operator []=(int index, C value) {}
}

void testFunction4<T4 extends List<T4>>() {
  debugger(); // LINE_A
  print('T4 = $T4');
}

void testFunction3<T3, S3 extends T3>() {
  debugger(); // LINE_B
  print('T3 = $T3');
  print('S3 = $S3');
}

void testFunction2<E extends String>(List<E> x) {
  debugger(); // LINE_C
  print('x = $x');
}

void testFunction() {
  testFunction2<String>(<String>['a', 'b', 'c']);
  testFunction3<A, B>();
  testFunction4<C>();
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
