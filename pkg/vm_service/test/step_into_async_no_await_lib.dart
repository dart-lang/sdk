// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'common/test_helper.dart';

// :async_op will not be captured in this function because it never needs to
// reschedule it.
Future<void> asyncWithoutAwait() async {
  print('asyncWithoutAwait'); // LINE_A
}

void testMain() {
  debugger(); // LINE_B
  asyncWithoutAwait(); // LINE_C
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
