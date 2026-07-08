// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer';
import 'common/test_helper.dart';

const int numberOfMicrotasksToSchedule = 5;

Future<void> testeeMain() async {
  for (int i = 0; i < numberOfMicrotasksToSchedule; i++) {
    scheduleMicrotask(() {});
    debugger();
    // Give the microtask that we just scheduled an opportunity to run.
    await Future.delayed(const Duration(milliseconds: 1));
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
