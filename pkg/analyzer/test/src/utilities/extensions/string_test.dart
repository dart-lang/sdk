// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IterableOfStringExtensionTest);
    defineReflectiveTests(StringExtensionTest);
  });
}

@reflectiveTest
class IterableOfStringExtensionTest {
  void test_commaSeparatedWithAnd_five() {
    expect(<String>['a', 'b', 'c', 'd', 'e'].commaSeparatedWithAnd,
        'a, b, c, d, and e');
  }

  void test_commaSeparatedWithAnd_one() {
    expect(<String>['a'].commaSeparatedWithAnd, 'a');
  }

  void test_commaSeparatedWithAnd_three() {
    expect(<String>['a', 'b', 'c'].commaSeparatedWithAnd, 'a, b, and c');
  }

  void test_commaSeparatedWithAnd_three_iterable() {
    expect(
      <String>['a', 'b', 'c'].reversed.commaSeparatedWithAnd,
      'c, b, and a',
    );
  }

  void test_commaSeparatedWithAnd_two() {
    expect(<String>['a', 'b'].commaSeparatedWithAnd, 'a and b');
  }

  void test_commaSeparatedWithAnd_zero() {
    expect(<String>[].commaSeparatedWithAnd, isEmpty);
  }

  void test_commaSeparatedWithOr_five() {
    expect(<String>['a', 'b', 'c', 'd', 'e'].commaSeparatedWithOr,
        'a, b, c, d, or e');
  }

  void test_commaSeparatedWithOr_one() {
    expect(<String>['a'].commaSeparatedWithOr, 'a');
  }

  void test_commaSeparatedWithOr_three() {
    expect(<String>['a', 'b', 'c'].commaSeparatedWithOr, 'a, b, or c');
  }

  void test_commaSeparatedWithOr_two() {
    expect(<String>['a', 'b'].commaSeparatedWithOr, 'a or b');
  }

  void test_commaSeparatedWithOr_zero() {
    expect(<String>[].commaSeparatedWithOr, isEmpty);
  }

  void test_quotedAndCommaSeparatedWithAnd_one() {
    expect(<String>['a'].quotedAndCommaSeparatedWithAnd, "'a'");
  }

  void test_quotedAndCommaSeparatedWithAnd_three() {
    expect(<String>['a', 'b', 'c'].quotedAndCommaSeparatedWithAnd,
        "'a', 'b', and 'c'");
  }

  void test_quotedAndCommaSeparatedWithAnd_two() {
    expect(<String>['a', 'b'].quotedAndCommaSeparatedWithAnd, "'a' and 'b'");
  }

  void test_quotedAndCommaSeparatedWithAnd_zero() {
    expect(<String>[].quotedAndCommaSeparatedWithAnd, isEmpty);
  }

  void test_quotedAndCommaSeparatedWithOr_one() {
    expect(<String>['a'].quotedAndCommaSeparatedWithOr, "'a'");
  }

  void test_quotedAndCommaSeparatedWithOr_three() {
    expect(<String>['a', 'b', 'c'].quotedAndCommaSeparatedWithOr,
        "'a', 'b', or 'c'");
  }

  void test_quotedAndCommaSeparatedWithOr_two() {
    expect(<String>['a', 'b'].quotedAndCommaSeparatedWithOr, "'a' or 'b'");
  }

  void test_quotedAndCommaSeparatedWithOr_zero() {
    expect(<String>[].quotedAndCommaSeparatedWithOr, isEmpty);
  }
}

@reflectiveTest
class StringExtensionTest {
  void test_ifEqualThen_equal() {
    expect('foo'.ifEqualThen('foo', 'bar'), 'bar');
  }

  void test_ifEqualThen_notEqual() {
    expect('notFoo'.ifEqualThen('foo', 'bar'), 'notFoo');
  }

  void test_ifNotEmptyOrElse_empty() {
    expect(''.ifNotEmptyOrElse('orElse'), 'orElse');
  }

  void test_ifNotEmptyOrElse_notEmpty() {
    expect('test'.ifNotEmptyOrElse('orElse'), 'test');
  }

  void test_isDigit() {
    for (var c in '0123456789'.codeUnits) {
      expect(c.isDigit, isTrue);
    }
    expect(' '.codeUnitAt(0).isDigit, isFalse);
    expect('A'.codeUnitAt(0).isDigit, isFalse);
  }

  void test_isLetter() {
    for (var c in 'abcdefghijklmnopqrstuvwxyz'.codeUnits) {
      expect(c.isLetter, isTrue);
    }
    for (var c in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.codeUnits) {
      expect(c.isLetter, isTrue);
    }
    expect(' '.codeUnitAt(0).isLetter, isFalse);
    expect('0'.codeUnitAt(0).isLetter, isFalse);
  }

  void test_isLetterOrDigit() {
    for (var c in 'abcdefghijklmnopqrstuvwxyz'.codeUnits) {
      expect(c.isLetterOrDigit, isTrue);
    }
    for (var c in 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.codeUnits) {
      expect(c.isLetterOrDigit, isTrue);
    }
    for (var c in '0123456789'.codeUnits) {
      expect(c.isLetterOrDigit, isTrue);
    }
    expect(' '.codeUnitAt(0).isLetterOrDigit, isFalse);
    expect('.'.codeUnitAt(0).isLetterOrDigit, isFalse);
  }

  void test_isSpace() {
    expect(' '.codeUnitAt(0).isSpace, isTrue);
    expect('\t'.codeUnitAt(0).isSpace, isTrue);
    expect('\r'.codeUnitAt(0).isSpace, isFalse);
    expect('\n'.codeUnitAt(0).isSpace, isFalse);
    expect('0'.codeUnitAt(0).isSpace, isFalse);
    expect('A'.codeUnitAt(0).isSpace, isFalse);
  }

  void test_isWhitespace() {
    expect(' '.codeUnitAt(0).isWhitespace, isTrue);
    expect('\t'.codeUnitAt(0).isWhitespace, isTrue);
    expect('\r'.codeUnitAt(0).isWhitespace, isTrue);
    expect('\n'.codeUnitAt(0).isWhitespace, isTrue);
    expect('0'.codeUnitAt(0).isWhitespace, isFalse);
    expect('A'.codeUnitAt(0).isWhitespace, isFalse);
  }

  void test_removeSuffix() {
    expect('01234'.removeSuffix(''), '01234');
    expect('01234'.removeSuffix('4'), '0123');
    expect('01234'.removeSuffix('34'), '012');
    expect('01234'.removeSuffix('01234'), '');
    expect('01234'.removeSuffix('012345'), isNull);
    expect('01234'.removeSuffix('5'), isNull);
  }
}
