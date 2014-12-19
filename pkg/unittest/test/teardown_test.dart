// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.teardown_test;

import 'package:unittest/unittest.dart';

import 'package:metatest/metatest.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  expectTestsPass('teardown test', () {
    var tornDown = false;

    group('a', () {
      tearDown(() {
        tornDown = true;
      });
      test('test', () {});
    });

    test('expect teardown', () {
      expect(tornDown, isTrue);
    });
  });
}
