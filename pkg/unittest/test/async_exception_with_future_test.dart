// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittestTest;

import 'dart:async';
import 'dart:isolate';

import 'package:unittest/unittest.dart';

part 'utils.dart';

var testName = 'async exception with future test';

var testFunction = (TestConfiguration testConfig) {
  tearDown(() { testConfig.teardown = 'teardown'; });
  test(testName, () {
    // The "throw" statement below should terminate the test immediately.
    // The framework should not wait for the future to complete.
    // tearDown should still execute.
    _defer(() { throw "error!"; });
    return new Completer().future;
  });
};

final expected = buildStatusString(0, 1, 0, testName,
    message: 'Caught error!', teardown: 'teardown');
