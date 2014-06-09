// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittestTest;

import 'dart:async';
import 'dart:isolate';

import 'package:unittest/unittest.dart';

part 'utils.dart';

var testName = 'late exception test';

var testFunction = (_) {
  test('testOne', () { expect(true, isTrue); });
  test('testTwo', () { expect(true, isFalse); });
  test('testThree', () {
    var done = expectAsync(() {});
    _defer(() {
      expect(true, isTrue);
      done();
    });
  });
};

final expected = buildStatusString(2, 1, 0,
    'testOne::testTwo:Expected: false Actual: <true>:testThree');
