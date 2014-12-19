// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.exception_test;

import 'package:unittest/unittest.dart';

import 'package:metatest/metatest.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  expectTestResults('good setup/good teardown', () {
    test('test', () {
      throw new Exception('Fail.');
    });
  }, [{
    'result': 'error',
    'message': 'Test failed: Caught Exception: Fail.'
  }]);
}
