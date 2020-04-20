// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/utilities/strings.dart';
import 'package:test/test.dart' hide isEmpty;
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(StringsTest);
  });
}

@reflectiveTest
class StringsTest {
  void test_capitalize() {
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

  void test_computeSimpleDiff() {
    void assertDiff(String oldStr, String newStr) {
      var diff = computeSimpleDiff(oldStr, newStr);
      expect(diff.offset, isNonNegative);
      expect(diff.length, isNonNegative);
      var applied = oldStr.substring(0, diff.offset) +
          diff.replacement +
          oldStr.substring(diff.offset + diff.length);
      expect(applied, newStr);
    }

    assertDiff('', '');
    assertDiff('', 'a');
    assertDiff('abc', '');
    assertDiff('abcd', 'acd');
    assertDiff('a', 'b');
    assertDiff('12345xyz', '12345abcxyz');
    assertDiff('12345xyz', '12345xyzabc');
    assertDiff('abbc', 'abbbc');
    assertDiff('abbbbc', 'abbbbbbc');
  }

  void test_countMatches() {
    expect(countMatches(null, null), 0);
    expect(countMatches('abc', null), 0);
    expect(countMatches(null, 'abc'), 0);
    expect(countMatches('ababa', 'a'), 3);
    expect(countMatches('ababa', 'ab'), 2);
    expect(countMatches('aaabaa', 'aa'), 2);
  }

  void test_findCommonPrefix() {
    expect(findCommonPrefix('abc', 'xyz'), 0);
    expect(findCommonPrefix('1234abcdef', '1234xyz'), 4);
    expect(findCommonPrefix('123', '123xyz'), 3);
  }

  void test_findCommonSuffix() {
    expect(findCommonSuffix('abc', 'xyz'), 0);
    expect(findCommonSuffix('abcdef1234', 'xyz1234'), 4);
    expect(findCommonSuffix('123', 'xyz123'), 3);
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
    for (var c in '0123456789'.codeUnits) {
      expect(isDigit(c), isTrue);
    }
    expect(isDigit(' '.codeUnitAt(0)), isFalse);
    expect(isDigit('A'.codeUnitAt(0)), isFalse);
  }

  void test_isLetter() {
    for (var c in 'abcdefghijklmnopqrstuvwxyz'.codeUnits) {
      expect(isLetter(c), isTrue);
    }
    for (var c in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.codeUnits) {
      expect(isLetter(c), isTrue);
    }
    expect(isLetter(' '.codeUnitAt(0)), isFalse);
    expect(isLetter('0'.codeUnitAt(0)), isFalse);
  }

  void test_isLetterOrDigit() {
    for (var c in 'abcdefghijklmnopqrstuvwxyz'.codeUnits) {
      expect(isLetterOrDigit(c), isTrue);
    }
    for (var c in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.codeUnits) {
      expect(isLetterOrDigit(c), isTrue);
    }
    for (var c in '0123456789'.codeUnits) {
      expect(isLetterOrDigit(c), isTrue);
    }
    expect(isLetterOrDigit(' '.codeUnitAt(0)), isFalse);
    expect(isLetterOrDigit('.'.codeUnitAt(0)), isFalse);
  }

  void test_isSpace() {
    expect(isSpace(' '.codeUnitAt(0)), isTrue);
    expect(isSpace('\t'.codeUnitAt(0)), isTrue);
    expect(isSpace('\r'.codeUnitAt(0)), isFalse);
    expect(isSpace('\n'.codeUnitAt(0)), isFalse);
    expect(isSpace('0'.codeUnitAt(0)), isFalse);
    expect(isSpace('A'.codeUnitAt(0)), isFalse);
  }

  void test_isWhitespace() {
    expect(isWhitespace(' '.codeUnitAt(0)), isTrue);
    expect(isWhitespace('\t'.codeUnitAt(0)), isTrue);
    expect(isWhitespace('\r'.codeUnitAt(0)), isTrue);
    expect(isWhitespace('\n'.codeUnitAt(0)), isTrue);
    expect(isWhitespace('0'.codeUnitAt(0)), isFalse);
    expect(isWhitespace('A'.codeUnitAt(0)), isFalse);
  }

  void test_removeEnd() {
    expect(removeEnd(null, 'x'), null);
    expect(removeEnd('abc', null), 'abc');
    expect(removeEnd('www.domain.com', '.com.'), 'www.domain.com');
    expect(removeEnd('www.domain.com', 'domain'), 'www.domain.com');
    expect(removeEnd('www.domain.com', '.com'), 'www.domain');
  }

  void test_repeat() {
    expect(repeat('x', 0), '');
    expect(repeat('x', 5), 'xxxxx');
    expect(repeat('abc', 3), 'abcabcabc');
  }

  void test_shorten() {
    expect(shorten('', 10), '');
    expect(shorten('0', 10), '0');
    expect(shorten('012', 10), '012');
    expect(shorten('0123456789', 10), '0123456789');
    expect(shorten('0123456789abcd', 10), '0123...bcd');
    expect(shorten('0123456789abcde', 10), '0123...cde');
    expect(shorten('0123456789abcdef', 10), '0123...def');
    expect(shorten('0123456789abcdef', 11), '0123...cdef');
    expect(shorten('0123456789abcdef', 12), '01234...cdef');
  }
}
