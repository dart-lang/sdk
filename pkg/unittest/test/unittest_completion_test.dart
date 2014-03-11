// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittestTest;
import 'dart:isolate';
import 'dart:async';
import 'package:unittest/unittest.dart';

part 'unittest_test_utils.dart';

var testName = 'completion test';

var testFunction = (TestConfiguration testConfig) {
  test(testName, () {
    var _callback;
    _callback = expectAsyncUntil(() {
      if (++testConfig.count < 10) {
        _defer(_callback);
      }
    },
    () => (testConfig.count == 10));
    _defer(_callback);
  });
};

var expected = buildStatusString(1, 0, 0, testName, count: 10);
