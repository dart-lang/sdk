// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittestTest;

import 'dart:async';
import 'dart:isolate';

import 'package:unittest/unittest.dart';

part 'utils.dart';

var testName = 'async setup teardown test';

var testFunction = (_) {
  group('good setup/good teardown', () {
    setUp(() {
      return new Future.value(0);
    });
    tearDown(() {
      return new Future.value(0);
    });
    test('foo1', () {});
  });
  group('good setup/bad teardown', () {
    setUp(() {
      return new Future.value(0);
    });
    tearDown(() {
      return new Future.error("Failed to complete tearDown");
    });
    test('foo2', () {});
  });
  group('bad setup/good teardown', () {
    setUp(() {
      return new Future.error("Failed to complete setUp");
    });
    tearDown(() {
      return new Future.value(0);
    });
    test('foo3', () {});
  });
  group('bad setup/bad teardown', () {
    setUp(() {
      return new Future.error("Failed to complete setUp");
    });
    tearDown(() {
      return new Future.error("Failed to complete tearDown");
    });
    test('foo4', () {});
  });
  // The next test is just to make sure we make steady progress
  // through the tests.
  test('post groups', () {});
};

final expected = buildStatusString(2, 0, 3,
    'good setup/good teardown foo1::'
    'good setup/bad teardown foo2:'
    'Teardown failed: Caught Failed to complete tearDown:'
    'bad setup/good teardown foo3:'
    'Setup failed: Caught Failed to complete setUp:'
    'bad setup/bad teardown foo4:'
    'Setup failed: Caught Failed to complete setUp:'
    'post groups');
