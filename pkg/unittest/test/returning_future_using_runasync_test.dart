// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.returning_future_using_runasync_test;

import 'dart:async';

import 'package:metatest/metatest.dart';
import 'package:unittest/unittest.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  expectTestResults('test returning future using scheduleMicrotask', () {
    test("successful", () {
      return new Future.sync(() {
        scheduleMicrotask(() {
          expect(true, true);
        });
      });
    });
    test("fail1", () {
      var callback = expectAsync(() {});
      return new Future.sync(() {
        scheduleMicrotask(() {
          expect(true, false);
          callback();
        });
      });
    });
    test('error1', () {
      var callback = expectAsync(() {});
      var excesscallback = expectAsync(() {});
      return new Future.sync(() {
        scheduleMicrotask(() {
          excesscallback();
          excesscallback();
          callback();
        });
      });
    });
    test("fail2", () {
      var callback = expectAsync(() {});
      return new Future.sync(() {
        scheduleMicrotask(() {
          fail('failure');
          callback();
        });
      });
    });
    test('error2', () {
      var callback = expectAsync(() {});
      var excesscallback = expectAsync(() {});
      return new Future.sync(() {
        scheduleMicrotask(() {
          excesscallback();
          excesscallback();
          excesscallback();
          callback();
        });
      });
    });
    test('foo6', () {
    });
  }, [{
    'description': 'successful',
    'result': 'pass',
  }, {
    'description': 'fail1',
    'message': 'Expected: <false>\n' '  Actual: <true>\n' '',
    'result': 'fail',
  }, {
    'description': 'error1',
    'message': 'Callback called more times than expected (1).',
    'result': 'fail',
  }, {
    'description': 'fail2',
    'message': 'failure',
    'result': 'fail',
  }, {
    'description': 'error2',
    'message': 'Callback called more times than expected (1).',
    'result': 'fail',
  }, {
    'description': 'foo6',
    'result': 'pass',
  }]);
}
