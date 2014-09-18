// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.protect_async_test;

import 'dart:async';

import 'package:unittest/unittest.dart';

import 'package:metatest/metatest.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  expectTestResults('protectAsync', () {
    test('protectAsync0', () {
      var protected = () {
        throw new StateError('error during protectAsync0');
      };
      new Future(protected);
    });

    test('protectAsync1', () {
      var protected = (arg) {
        throw new StateError('error during protectAsync1: $arg');
      };
      new Future(() => protected('one arg'));
    });

    test('protectAsync2', () {
      var protected = (arg1, arg2) {
        throw new StateError('error during protectAsync2: $arg1, $arg2');
      };
      new Future(() => protected('arg1', 'arg2'));
    });

    test('throw away 1', () {
      return new Future(() {});
    });
  }, [{
    'result': 'error',
    'message': 'Caught Bad state: error during protectAsync0'
  }, {
    'result': 'error',
    'message': 'Caught Bad state: error during protectAsync1: one arg'
  }, {
    'result': 'error',
    'message': 'Caught Bad state: error during protectAsync2: arg1, arg2'
  }, {
    'result': 'pass',
    'message': ''
  }]);
}
