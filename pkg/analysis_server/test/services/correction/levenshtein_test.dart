// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.correction.levenshtein;

import 'package:analysis_server/src/services/correction/levenshtein.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(LevenshteinTest);
}

@ReflectiveTestCase()
class LevenshteinTest {
  void test_different_caseInsensitive() {
    expect(levenshtein('Saturday', 'sunday', 5, caseSensitive: false), 3);
    expect(levenshtein('SaturDay', 'sunday', 5, caseSensitive: false), 3);
  }

  void test_different_onThreshold() {
    expect(levenshtein('', 'abcde', 5), 5);
    expect(levenshtein('abcde', '', 5), 5);
  }

  void test_different_overThreshold() {
    expect(levenshtein('', 'abcde', 2), LEVENSHTEIN_MAX);
    expect(levenshtein('abcde', '', 2), LEVENSHTEIN_MAX);
  }

  void test_different_overThreshold_length() {
    expect(levenshtein('a', 'abcdefgh', 5), LEVENSHTEIN_MAX);
    expect(levenshtein('abcdefgh', 'a', 5), LEVENSHTEIN_MAX);
  }

  void test_different_underThreshold() {
    expect(levenshtein('String', 'Stirng', 5), 2);
    expect(levenshtein('kitten', 'sitting', 5), 3);
    expect(levenshtein('Saturday', 'Sunday', 5), 3);
  }

  void test_negativeThreshold() {
    expect(() {
      levenshtein('', '', -5);
    }, throws);
  }

  void test_null() {
    expect(() {
      levenshtein('', null, 5);
    }, throws);
    expect(() {
      levenshtein(null, '', 5);
    }, throws);
  }

  void test_same() {
    expect(levenshtein('', '', 5), 0);
    expect(levenshtein('test', 'test', 5), 0);
  }

  void test_same_caseInsensitive() {
    expect(levenshtein('test', 'Test', 5, caseSensitive: false), 0);
  }
}
