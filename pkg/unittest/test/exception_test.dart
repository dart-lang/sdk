// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittestTest;

import 'dart:async';
import 'dart:isolate';

import 'package:unittest/unittest.dart';

part 'utils.dart';

var testName = 'exception test';

var testFunction = (_) {
  test(testName, () { throw new Exception('Fail.'); });
};

var expected =  buildStatusString(0, 0, 1, testName,
    message: 'Test failed: Caught Exception: Fail.');
