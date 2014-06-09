// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittestTest;

import 'dart:async';
import 'dart:isolate';

import 'package:unittest/unittest.dart';

part 'utils.dart';

var testFunction = (TestConfiguration testConfig) {
  List<int> _getArgs([a = 0, b = 0, c = 0, d = 0, e = 0, f = 0]) {
    testConfig.count++;
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
      testConfig.count++;
    })();
  });
};

final expected = startsWith('1:0:2:3:3:::null:expect async args::'
    'invoked with too many args:Test failed:');
