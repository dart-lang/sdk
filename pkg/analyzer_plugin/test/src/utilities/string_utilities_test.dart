// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/src/utilities/string_utilities.dart';
import 'package:test/test.dart' hide isEmpty;
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StringUtilitiesTest);
  });
}

@reflectiveTest
class StringUtilitiesTest {
  void test_getCamelWords() {
    expect(getCamelWords(null), []);
    expect(getCamelWords(''), []);
    expect(getCamelWords('getCamelWords'), ['get', 'Camel', 'Words']);
    expect(getCamelWords('getHTMLText'), ['get', 'HTML', 'Text']);
  }

  void test_isEmpty() {
    expect(isEmpty(null), isTrue);
    expect(isEmpty(''), isTrue);
    expect(isEmpty('X'), isFalse);
    expect(isEmpty(' '), isFalse);
  }

  void test_isLowerCase() {
    for (int c in 'abcdefghijklmnopqrstuvwxyz'.codeUnits) {
      expect(isLowerCase(c), isTrue);
    }
    for (int c in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.codeUnits) {
      expect(isLowerCase(c), isFalse);
    }
    expect(isLowerCase(' '.codeUnitAt(0)), isFalse);
    expect(isLowerCase('0'.codeUnitAt(0)), isFalse);
  }

  void test_isUpperCase() {
    for (int c in 'abcdefghijklmnopqrstuvwxyz'.codeUnits) {
      expect(isUpperCase(c), isFalse);
    }
    for (int c in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.codeUnits) {
      expect(isUpperCase(c), isTrue);
    }
    expect(isUpperCase(' '.codeUnitAt(0)), isFalse);
    expect(isUpperCase('0'.codeUnitAt(0)), isFalse);
  }

  void test_removeStart() {
    expect(removeStart(null, 'x'), null);
    expect(removeStart('abc', null), 'abc');
    expect(removeStart('abcTest', 'abc'), 'Test');
    expect(removeStart('my abcTest', 'abc'), 'my abcTest');
  }
}
