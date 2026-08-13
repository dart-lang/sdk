// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';

Future<void> testMain() async {
  debugger(); // LINE_0
  print('hi'); // LINE_A
  print('yep'); // LINE_B
  print('zoo'); // LINE_C
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
