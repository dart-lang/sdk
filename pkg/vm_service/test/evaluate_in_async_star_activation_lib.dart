// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'common/test_helper.dart';

Stream<int> generator() async* {
  final x = 3;
  final y = 4;
  debugger(); // LINE_A
  yield y;
  final z = x + y;
  debugger(); // LINE_B
  yield z;
}

Future<void> testFunction() async {
  await for (var _ in generator()) {}
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
