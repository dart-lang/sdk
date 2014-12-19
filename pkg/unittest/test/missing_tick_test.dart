// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.missing_tick_test;

import 'package:unittest/unittest.dart';

import 'package:metatest/metatest.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message, timeout: const Duration(seconds: 1));

  expectTestResults('missing tick', () {

    test('test that should time out', () {
      expectAsync(() {});
    });
  }, [{
    'description': 'test that should time out',
    'message': 'Test timed out after 1 seconds.',
    'result': 'error',
  }]);
}
