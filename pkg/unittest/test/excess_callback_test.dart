// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.excess_callback_test;

import 'dart:async';

import 'package:metatest/metatest.dart';
import 'package:unittest/unittest.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  var count = 0;

  expectTestResults('excess callback test', () {
    test('test', () {
      var _callback0 = expectAsync(() => ++count);
      var _callback1 = expectAsync(() => ++count);
      var _callback2 = expectAsync(() {
        _callback1();
        _callback1();
        _callback0();
      });
      new Future.sync(_callback2);
    });

    test('verify count', () {
      expect(count, 1);
    });
  }, [{
    'description': 'test',
    'message': 'Callback called more times than expected (1).',
    'result': 'fail'
  }, {
    'description': 'verify count',
    'result': 'pass',
  }]);
}
