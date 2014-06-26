// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittestTest;

import 'dart:async';
import 'dart:isolate';

import 'package:unittest/unittest.dart';

part 'utils.dart';

var testName = 'group name test';

var testFunction = (_) {
  group('a', () {
    test('a', () {});
    group('b', () {
      test('b', () {});
    });
  });
};

var expected = buildStatusString(2, 0, 0, 'a a::a b b');
