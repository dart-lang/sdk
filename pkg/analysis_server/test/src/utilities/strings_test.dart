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

  void test_removeEnd() {
    expect(removeEnd(null, 'x'), null);
    expect(removeEnd('abc', null), 'abc');
    expect(removeEnd('www.domain.com', '.com.'), 'www.domain.com');
    expect(removeEnd('www.domain.com', 'domain'), 'www.domain.com');
    expect(removeEnd('www.domain.com', '.com'), 'www.domain');
  }
}
