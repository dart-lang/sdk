// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library mock.mock_stepwise_negative_test;

import 'package:unittest/unittest.dart' show test;
import 'package:mock/mock.dart';

main() {
  test('Mocking: stepwiseValidate', () {
    LogEntryList logList = new LogEntryList('test');
    for (var i = 0; i < 10; i++) {
      LogEntry e = new LogEntry(null, 'foo', [i], Action.IGNORE);
      logList.add(e);
    }
    int total = 0;
    logList.stepwiseValidate((log, pos) => 0);
  });
}
