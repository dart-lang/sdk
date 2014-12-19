// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.expect_async_args_test;

import 'package:unittest/unittest.dart';

import 'package:metatest/metatest.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  expectTestResults('expect async args', () {
    var count = 0;
    List<int> _getArgs([a = 0, b = 0, c = 0, d = 0, e = 0, f = 0]) {
      count++;
      return [a, b, c, d, e, f];
    }

    test('expect async args', () {
      expect(expectAsync(_getArgs)(), [0, 0, 0, 0, 0, 0]);
      expect(expectAsync(_getArgs)(5), [5, 0, 0, 0, 0, 0]);
      expect(expectAsync(_getArgs)(1, 2, 3, 4, 5, 6), [1, 2, 3, 4, 5, 6]);
    });

    test('invoked with too many args', () {
      expectAsync(_getArgs)(1, 2, 3, 4, 5, 6, 7);
    });

    test('created with too many args', () {
      expectAsync((a1, a2, a3, a4, a5, a6, a7) {
        count++;
      })();
    });

    test('verify count', () {
      expect(count, 3);
    });
  }, [{
    'description': 'expect async args',
    'result': 'pass',
  }, {
    'description': 'invoked with too many args',
    'result': 'error',
  }, {
    'description': 'created with too many args',
    'result': 'error',
  }, {
    'description': 'verify count',
    'result': 'pass',
  }]);
}
