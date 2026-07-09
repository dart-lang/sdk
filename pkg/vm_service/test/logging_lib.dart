// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:developer';

import 'package:logging/logging.dart';

import 'common/test_helper.dart';

void init() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((logRecord) {
    log(
      logRecord.message,
      time: logRecord.time,
      sequenceNumber: logRecord.sequenceNumber,
      level: logRecord.level.value,
      name: logRecord.loggerName,
      zone: null,
      error: logRecord.error,
      stackTrace: logRecord.stackTrace,
    );
  });
}

void run() {
  debugger(); // LINE_A
  Logger.root.fine('Hey Buddy!');
  debugger(); // LINE_B
  Logger.root.info('YES');
}

Future<void> main([List<String> args = const <String>[]]) {
  return startServiceTest(
    testeeBefore: init,
    testeeConcurrent: run,
  );
}
