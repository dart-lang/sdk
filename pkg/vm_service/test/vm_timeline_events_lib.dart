// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:developer' as dev;

import 'common/test_helper.dart';

Future<void> primeDartTimeline() async {
  while (true) {
    dev.Timeline.startSync('apple');
    dev.Timeline.finishSync();
    // Give the VM a chance to send the timeline events. This test is
    // significantly slower if we loop without yielding control after each
    // iteration.
    await Future.delayed(const Duration(milliseconds: 1));
  }
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: primeDartTimeline);
}
