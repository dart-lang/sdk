// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.middle_exception_test;

import 'dart:async';

import 'package:metatest/metatest.dart';
import 'package:unittest/unittest.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  expectTestResults('late exception test', () {
    test('testOne', () {
      expect(true, isTrue);
    });
    test('testTwo', () {
      expect(true, isFalse);
    });
    test('testThree', () {
      var done = expectAsync(() {});
      new Future.sync(() {
        expect(true, isTrue);
        done();
      });
    });
  }, [{
    'result': 'pass'
  }, {
    'result': 'fail',
  }, {
    'result': 'pass'
  }]);
}
