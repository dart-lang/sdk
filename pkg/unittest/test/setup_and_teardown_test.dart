// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittest.setup_and_teardown_test;

import 'package:unittest/unittest.dart';

import 'package:metatest/metatest.dart';

void main() => initTests(_test);

void _test(message) {
  initMetatest(message);

  expectTestsPass('setup and teardown test', () {
    var hasSetup = false;
    var hasTeardown = false;

    group('a', () {
      setUp(() {
        hasSetup = true;
      });
      tearDown(() {
        hasTeardown = true;
      });
      test('test', () {});
    });

    test('verify', () {
      expect(hasSetup, isTrue);
      expect(hasTeardown, isTrue);
    });
  });
}
