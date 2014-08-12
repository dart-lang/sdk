// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library test.services.correction.strings;

import 'package:analysis_services/src/correction/strings.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart' hide isEmpty;



main() {
  groupSep = ' | ';
  runReflectiveTests(StringsTest);
}


@ReflectiveTestCase()
class StringsTest {
  void test_capitalize() {
    expect(capitalize(null), null);
    expect(capitalize(''), '');
    expect(capitalize('a'), 'A');
    expect(capitalize('abc'), 'Abc');
    expect(capitalize('abc def'), 'Abc def');
    expect(capitalize('ABC'), 'ABC');
  }

  void test_compareStrings() {
    expect(compareStrings(null, null), 0);
    expect(compareStrings(null, 'b'), 1);
    expect(compareStrings('a', null), -1);
    expect(compareStrings('a', 'b'), -1);
    expect(compareStrings('b', 'a'), 1);
  }

  void test_isBlank() {
    expect(isBlank(null), isTrue);
    expect(isBlank(''), isTrue);
    expect(isBlank(' '), isTrue);
    expect(isBlank('\t'), isTrue);
    expect(isBlank('  '), isTrue);
    expect(isBlank('X'), isFalse);
  }

  void test_isDigit() {
    for (int c in '0123456789'.codeUnits) {
      expect(isDigit(c), isTrue);
    }
    expect(isDigit(' '.codeUnitAt(0)), isFalse);
    expect(isDigit('A'.codeUnitAt(0)), isFalse);
  }

  void test_isEmpty() {
    expect(isEmpty(null), isTrue);
    expect(isEmpty(''), isTrue);
    expect(isEmpty('X'), isFalse);
    expect(isEmpty(' '), isFalse);
  }

  void test_isLetter() {
    for (int c in 'abcdefghijklmnopqrstuvwxyz'.codeUnits) {
      expect(isLetter(c), isTrue);
    }
    for (int c in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.codeUnits) {
      expect(isLetter(c), isTrue);
    }
    expect(isLetter(' '.codeUnitAt(0)), isFalse);
    expect(isLetter('0'.codeUnitAt(0)), isFalse);
  }

  void test_isLetterOrDigit() {
    for (int c in 'abcdefghijklmnopqrstuvwxyz'.codeUnits) {
      expect(isLetterOrDigit(c), isTrue);
    }
    for (int c in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.codeUnits) {
      expect(isLetterOrDigit(c), isTrue);
    }
    for (int c in '0123456789'.codeUnits) {
      expect(isLetterOrDigit(c), isTrue);
    }
    expect(isLetterOrDigit(' '.codeUnitAt(0)), isFalse);
    expect(isLetterOrDigit('.'.codeUnitAt(0)), isFalse);
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

  void test_isSpace() {
    expect(isSpace(' '.codeUnitAt(0)), isTrue);
    expect(isSpace('\t'.codeUnitAt(0)), isTrue);
    expect(isSpace('\r'.codeUnitAt(0)), isFalse);
    expect(isSpace('\n'.codeUnitAt(0)), isFalse);
    expect(isSpace('0'.codeUnitAt(0)), isFalse);
    expect(isSpace('A'.codeUnitAt(0)), isFalse);
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

  void test_isWhitespace() {
    expect(isWhitespace(' '.codeUnitAt(0)), isTrue);
    expect(isWhitespace('\t'.codeUnitAt(0)), isTrue);
    expect(isWhitespace('\r'.codeUnitAt(0)), isTrue);
    expect(isWhitespace('\n'.codeUnitAt(0)), isTrue);
    expect(isWhitespace('0'.codeUnitAt(0)), isFalse);
    expect(isWhitespace('A'.codeUnitAt(0)), isFalse);
  }

  void test_remove() {
    expect(remove(null, 'x'), null);
    expect(remove('abc', null), 'abc');
    expect(remove('abc abbc abbbc', 'b'), 'ac ac ac');
    expect(remove('abc abbc abbbc', 'bc'), 'a ab abb');
  }

  void test_removeStart() {
    expect(removeStart(null, 'x'), null);
    expect(removeStart('abc', null), 'abc');
    expect(removeStart('abcTest', 'abc'), 'Test');
    expect(removeStart('my abcTest', 'abc'), 'my abcTest');
  }

  void test_repeat() {
    expect(repeat('x', 0), '');
    expect(repeat('x', 5), 'xxxxx');
    expect(repeat('abc', 3), 'abcabcabc');
  }
}
