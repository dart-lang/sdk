// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittestTest;
import 'dart:isolate';
import 'dart:async';
import 'package:unittest/unittest.dart';

part 'unittest_test_utils.dart';

var testName = 'invalid ops throw while test is running';

var testFunction = (_) {
  test(testName, () {
    expect(() => test('test', () {}), throwsStateError);
    expect(() => solo_test('test', () {}), throwsStateError);
    expect(() => group('test', () {}), throwsStateError);
    expect(() => solo_group('test', () {}), throwsStateError);
    expect(() => setUp(() {}), throwsStateError);
    expect(() => tearDown(() {}), throwsStateError);
    expect(() => runTests(), throwsStateError);
  });
};

var expected = buildStatusString(1, 0, 0, testName);
