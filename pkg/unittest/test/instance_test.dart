// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library unittestTests;
import 'package:unittest/unittest.dart';

import 'test_utils.dart';

main() {
  initUtils();

  group('Type Matchers', () {
    test('isInstanceOf', () {
      shouldFail(0, new isInstanceOf<String>('String'),
          "Expected: an instance of String Actual: <0>");
      shouldPass('cow', new isInstanceOf<String>('String'));
    });

    test('throwsA', () {
      shouldPass(doesThrow, throwsA(equals('X')));
      shouldFail(doesThrow, throwsA(equals('Y')),
          matches("Expected: throws 'Y'.*"
          "Actual: <Closure.*"
          "Which: threw 'X'"));
    });
  });
}

