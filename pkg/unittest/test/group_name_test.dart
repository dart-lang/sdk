// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.group_name_test;

import 'package:unittest/unittest.dart';

import 'package:metatest/metatest.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  expectTestResults('group name test', () {
    group('a', () {
      test('a', () {});
      group('b', () {
        test('b', () {});
      });
    });
  }, [{
    'description': 'a a'
  }, {
    'description': 'a b b'
  }]);
}
