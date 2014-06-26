// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittestTest;

import 'dart:async';
import 'dart:isolate';

import 'package:unittest/unittest.dart';

part 'utils.dart';

var testName = 'excess callback test';

var testFunction = (TestConfiguration testConfig) {
  test(testName, () {
    var _callback0 = expectAsync(() => ++testConfig.count);
    var _callback1 = expectAsync(() => ++testConfig.count);
    var _callback2 = expectAsync(() {
      _callback1();
      _callback1();
      _callback0();
    });
    _defer(_callback2);
  });
};

var expected = buildStatusString(0, 1, 0, testName,
    count: 1, message: 'Callback called more times than expected (1).');
