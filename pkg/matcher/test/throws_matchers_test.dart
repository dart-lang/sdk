// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library matcher.core_matchers_test;

import 'package:matcher/matcher.dart';
import 'package:unittest/unittest.dart' show test, group;

import 'test_utils.dart';

void main() {
  initUtils();


  test('throws', () {
    shouldFail(doesNotThrow, throws,
        matches(
            r"Expected: throws"
            r"  Actual: <Closure(: \(\) => dynamic "
            r"from Function 'doesNotThrow': static\.)?>"
            r"   Which: did not throw"));
    shouldPass(doesThrow, throws);
    shouldFail(true, throws,
        "Expected: throws"
        "  Actual: <true>"
        "   Which: is not a Function or Future");
  });

  test('throwsA', () {
    shouldPass(doesThrow, throwsA(equals('X')));
    shouldFail(doesThrow, throwsA(equals('Y')),
        matches(
            r"Expected: throws 'Y'"
            r"  Actual: <Closure(: \(\) => dynamic "
            r"from Function 'doesThrow': static\.)?>"
            r"   Which: threw 'X'"));
  });

  test('throwsA', () {
    shouldPass(doesThrow, throwsA(equals('X')));
    shouldFail(doesThrow, throwsA(equals('Y')),
        matches("Expected: throws 'Y'.*"
        "Actual: <Closure.*"
        "Which: threw 'X'"));
  });


  group('exception/error matchers', () {
    test('throwsCyclicInitializationError', () {
      expect(() => _Bicycle.foo, throwsCyclicInitializationError);
    });

    test('throwsConcurrentModificationError', () {
      expect(() {
        var a = { 'foo': 'bar' };
        for (var k in a.keys) {
          a.remove(k);
        }
      }, throwsConcurrentModificationError);
    });

    test('throwsNullThrownError', () {
      expect(() => throw null, throwsNullThrownError);
    });
  });
}

class _Bicycle {
  static final foo = bar();

  static bar() {
    return foo + 1;
  }
}

