// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.async_exception_with_future_test;

import 'dart:async';

import 'package:metatest/metatest.dart';
import 'package:unittest/unittest.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  expectTestResults('async exception with future test', () {
    var tearDownHappened = false;

    tearDown(() {
      tearDownHappened = true;
    });

    test('test', () {
      expect(tearDownHappened, isFalse);
      // The "throw" statement below should terminate the test immediately.
      // The framework should not wait for the future to complete.
      // tearDown should still execute.
      new Future.sync(() {
        throw "error!";
      });
      return new Completer().future;
    });

    test('follow up', () {
      expect(tearDownHappened, isTrue);
    });

  }, [{
    'description': 'test',
    'message': 'Caught error!',
    'result': 'fail',
  }, {
    'description': 'follow up',
    'result': 'pass',
  }]);
}
