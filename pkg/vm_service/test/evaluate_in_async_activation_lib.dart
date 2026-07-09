// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';

import 'common/test_helper.dart';

Future<int> testFunction() async {
  final x = 3;
  final y = 4;
  debugger(); // LINE_A
  final z = await Future(() => x + y);
  debugger(); // LINE_B
  return z;
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testFunction);
}
