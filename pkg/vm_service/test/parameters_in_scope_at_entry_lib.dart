// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

String foo(String param) {
  return param;
}

String Function(String) fooClosure() {
  String theClosureFunction(String param) {
    return param;
  }

  return theClosureFunction;
}

void testMain() {
  debugger(); // LINE_A
  foo('in-scope'); // LINE_B

  final f = fooClosure();
  debugger(); // LINE_C
  f('in-scope'); // LINE_D
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
