// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.async_setup_teardown;

import 'dart:async';

import 'package:metatest/metatest.dart';
import 'package:unittest/unittest.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  expectTestsPass('good setup/good teardown', () {
    setUp(() {
      return new Future.value(0);
    });
    tearDown(() {
      return new Future.value(0);
    });
    test('foo1', () {});
  });

  expectTestResults('good setup/bad teardown', () {
    setUp(() {
      return new Future.value(0);
    });
    tearDown(() {
      return new Future.error("Failed to complete tearDown");
    });
    test('foo2', () {});
  }, [{
    'result': 'error',
    'message': 'Teardown failed: Caught Failed to complete tearDown'
  }]);

  expectTestResults('bad setup/good teardown', () {
    setUp(() {
      return new Future.error("Failed to complete setUp");
    });
    tearDown(() {
      return new Future.value(0);
    });
    test('foo3', () {});
  }, [{
    'result': 'error',
    'message': 'Setup failed: Caught Failed to complete setUp'
  }]);

  expectTestResults('bad setup/bad teardown', () {
    setUp(() {
      return new Future.error("Failed to complete setUp");
    });
    tearDown(() {
      return new Future.error("Failed to complete tearDown");
    });
    test('foo4', () {});
  }, [{
    'result': 'error',
    'message': 'Setup failed: Caught Failed to complete setUp'
  }]);
}
