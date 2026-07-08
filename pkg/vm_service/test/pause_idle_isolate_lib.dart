// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';
import 'dart:isolate' show ReceivePort;

import 'common/test_helper.dart';

late final ReceivePort receivePort;

void testMain() {
  receivePort = ReceivePort();
  debugger(); // LINE_A
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testMain);
}
