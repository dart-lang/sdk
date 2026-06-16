// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer' as dev;

import 'common/test_helper.dart';

void primeDartTimeline() {
  while (true) {
    dev.Timeline.startSync('apple'); // LINE_A
    dev.Timeline.finishSync();
    dev.debugger(); // LINE_B
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: primeDartTimeline);
}
