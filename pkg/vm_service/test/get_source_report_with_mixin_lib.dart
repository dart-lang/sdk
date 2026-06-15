// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';
import 'get_source_report_with_mixin_lib2.dart';
import 'get_source_report_with_mixin_lib3.dart';

void testFunction() {
  final Test1 test1 = Test1();
  test1.foo();
  final Test2 test2 = Test2();
  test2.bar();
  debugger(); // LINE_A
  print('done');
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
