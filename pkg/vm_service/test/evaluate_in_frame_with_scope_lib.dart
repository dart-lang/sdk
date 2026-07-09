// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';

late int thing1;
late int thing2;
late String thing3;

void testeeMain() {
  thing1 = 3;
  thing2 = 4;
  thing3 = 'hello';
  foo(42, 1984);
}

int foo(x, y) {
  final local = x + y;
  // ignore: unused_local_variable
  final local2 = Cow('hello $x and $y');
  debugger(); // LINE_A
  return local;
}

extension type Cow(String s) {
  String say() {
    return 'Moo, $s!';
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
