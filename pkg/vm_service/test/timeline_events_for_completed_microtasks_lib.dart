// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'common/test_helper.dart';

Future<void> primeTimeline() async {
  for (int i = 0; i < 5; i++) {
    scheduleMicrotask(() {});
  }
  // Yield to the event loop to allow the scheduled microtasks to run.
  await Future(() {});
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeBefore: primeTimeline);
}
