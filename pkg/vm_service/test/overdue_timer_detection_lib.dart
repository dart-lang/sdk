// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show sleep;

import 'common/test_helper.dart';

Future<void> testeeMain() async {
  final completer = Completer<void>();
  late final Timer t;
  t = Timer(
    const Duration(milliseconds: 100),
    () {
      t.cancel();
      completer.complete();
    },
  );

  // Sleep for 201 ms to force [t] to fire at least 100 ms late. This allows us
  // to expect to receive at least one 'TimerSignificantlyOverdue' event in
  // [tests] below, because a 'TimerSignificantlyOverdue' event should be fired
  // whenever a timer is identified to be at least 100 ms overdue.
  sleep(const Duration(milliseconds: 201));
  await completer.future;
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(testeeConcurrent: testeeMain);
}
