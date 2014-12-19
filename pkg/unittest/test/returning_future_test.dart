// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.returning_future_test;

import 'dart:async';

import 'package:metatest/metatest.dart';
import 'package:unittest/unittest.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  expectTestResults('returning futures', () {
    test("successful", () {
      return new Future.sync(() {
        expect(true, true);
      });
    });
    // We repeat the fail and error tests, because during development
    // I had a situation where either worked fine on their own, and
    // error/fail worked, but fail/error would time out.
    test("error1", () {
      var callback = expectAsync(() {});
      var excesscallback = expectAsync(() {});
      return new Future.sync(() {
        excesscallback();
        excesscallback();
        excesscallback();
        callback();
      });
    });
    test("fail1", () {
      return new Future.sync(() {
        expect(true, false);
      });
    });
    test("error2", () {
      var callback = expectAsync(() {});
      var excesscallback = expectAsync(() {});
      return new Future.sync(() {
        excesscallback();
        excesscallback();
        callback();
      });
    });
    test("fail2", () {
      return new Future.sync(() {
        fail('failure');
      });
    });
    test('foo5', () {
    });
  }, [{
    'result': 'pass'
  }, {
    'result': 'fail',
    'message': 'Callback called more times than expected (1).'
  }, {
    'result': 'fail',
    'message': 'Expected: <false>\n  Actual: <true>\n'
  }, {
    'result': 'fail',
    'message': 'Callback called more times than expected (1).'
  }, {
    'result': 'fail',
    'message': 'failure'
  }, {
    'result': 'pass'
  }]);
}
