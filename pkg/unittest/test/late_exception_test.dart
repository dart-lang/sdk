// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.late_exception_test;

import 'dart:async';

import 'package:metatest/metatest.dart';
import 'package:unittest/unittest.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  expectTestResults('late exception test', () {
    var f;
    test('testOne', () {
      f = expectAsync(() {});
      new Future.sync(f);
    });
    test('testTwo', () {
      new Future.sync(expectAsync(() {
        f();
      }));
    });
  }, [{
    'description': 'testOne',
    'message': 'Callback called (2) after test case testOne has already been '
        'marked as pass.',
    'result': 'error',
  }, {
    'description': 'testTwo',
    'result': 'pass',
  }]);
}
