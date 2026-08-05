// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer' show debugger;

import 'common/test_helper.dart';

({int? a}) getRecord() => (a: 1);

void testeeMain() {
  // ignore: prefer_final_locals
  late var x = getRecord();
  debugger(); // LINE_A
  print(x.a);
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
