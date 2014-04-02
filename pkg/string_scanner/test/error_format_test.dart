// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library string_scanner.error_format_test;

import 'package:string_scanner/string_scanner.dart';
import 'package:unittest/unittest.dart';

void main() {
  test('points to the first unconsumed character', () {
    var scanner = new StringScanner('foo bar baz');
    scanner.expect('foo ');
    expect(() => scanner.expect('foo'), throwsFormattedError('''
Expected "foo" on line 1, column 5.
foo bar baz
    ^'''));
  });

  test('prints the correct line', () {
    var scanner = new StringScanner('foo bar baz\ndo re mi\nearth fire water');
    scanner.expect('foo bar baz\ndo ');
    expect(() => scanner.expect('foo'), throwsFormattedError('''
Expected "foo" on line 2, column 4.
do re mi
   ^'''));
  });

  test('handles the beginning of the string correctly', () {
    var scanner = new StringScanner('foo bar baz');
    expect(() => scanner.expect('zap'), throwsFormattedError('''
Expected "zap" on line 1, column 1.
foo bar baz
^'''));
  });

  test('handles the end of the string correctly', () {
    var scanner = new StringScanner('foo bar baz');
    scanner.expect('foo bar baz');
    expect(() => scanner.expect('bang'), throwsFormattedError('''
Expected "bang" on line 1, column 12.
foo bar baz
           ^'''));
  });

  test('handles an empty string correctly', () {
    expect(() => new StringScanner('').expect('foo'), throwsFormattedError('''
Expected "foo" on line 1, column 1.

^'''));
  });

  group("expected name", () {
    test("uses the provided name", () {
      expect(() => new StringScanner('').expect('foo bar', name: 'zap'),
          throwsFormattedError('''
Expected zap on line 1, column 1.

^'''));
    });

    test("escapes string quotes", () {
      expect(() => new StringScanner('').expect('foo"bar'),
          throwsFormattedError('''
Expected "foo\\"bar" on line 1, column 1.

^'''));
    });

    test("escapes string backslashes", () {
      expect(() => new StringScanner('').expect('foo\\bar'),
          throwsFormattedError('''
Expected "foo\\\\bar" on line 1, column 1.

^'''));
    });

    test("prints PERL-style regexps", () {
      expect(() => new StringScanner('').expect(new RegExp(r'foo')),
          throwsFormattedError('''
Expected /foo/ on line 1, column 1.

^'''));
    });

    test("escape regexp forward slashes", () {
      expect(() => new StringScanner('').expect(new RegExp(r'foo/bar')),
          throwsFormattedError('''
Expected /foo\\/bar/ on line 1, column 1.

^'''));
    });

    test("does not escape regexp backslashes", () {
      expect(() => new StringScanner('').expect(new RegExp(r'foo\bar')),
          throwsFormattedError('''
Expected /foo\\bar/ on line 1, column 1.

^'''));
    });
  });
}

Matcher throwsFormattedError(String format) {
  return throwsA(predicate((error) {
    expect(error, isFormatException);
    expect(error.message, equals(format));
    return true;
  }));
}
