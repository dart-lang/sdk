// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittestTest;
import 'dart:isolate';
import 'dart:async';
import 'package:unittest/unittest.dart';

part 'unittest_test_utils.dart';

var testName = 'single failing test';

var testFunction = (_) {
  test(testName, () => expect(2 + 2, equals(5)));
};

var expected = buildStatusString(0, 1, 0, testName,
    message: 'Expected: <5> Actual: <4>');
