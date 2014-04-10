// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library string_scanner.expect_error_test;

import 'package:string_scanner/string_scanner.dart';
import 'package:unittest/unittest.dart';

import 'utils.dart';

void main() {
  test('points to the first unconsumed character', () {
    var scanner = new StringScanner('foo bar baz');
    scanner.expect('foo ');
    expect(() => scanner.expect('foo'), throwsFormattedError('''
Error on line 1, column 5: expected "foo".
foo bar baz
    ^'''));
  });

  test('prints the correct line', () {
    var scanner = new StringScanner('foo bar baz\ndo re mi\nearth fire water');
    scanner.expect('foo bar baz\ndo ');
    expect(() => scanner.expect('foo'), throwsFormattedError('''
Error on line 2, column 4: expected "foo".
do re mi
   ^'''));
  });

  test('handles the beginning of the string correctly', () {
    var scanner = new StringScanner('foo bar baz');
    expect(() => scanner.expect('zap'), throwsFormattedError('''
Error on line 1, column 1: expected "zap".
foo bar baz
^'''));
  });

  test('handles the end of the string correctly', () {
    var scanner = new StringScanner('foo bar baz');
    scanner.expect('foo bar baz');
    expect(() => scanner.expect('bang'), throwsFormattedError('''
Error on line 1, column 12: expected "bang".
foo bar baz
           ^'''));
  });

  test('handles an empty string correctly', () {
    expect(() => new StringScanner('').expect('foo'), throwsFormattedError('''
Error on line 1, column 1: expected "foo".

^'''));
  });

  group("expected name", () {
    test("uses the provided name", () {
      expect(() => new StringScanner('').expect('foo bar', name: 'zap'),
          throwsFormattedError('''
Error on line 1, column 1: expected zap.

^'''));
    });

    test("escapes string quotes", () {
      expect(() => new StringScanner('').expect('foo"bar'),
          throwsFormattedError('''
Error on line 1, column 1: expected "foo\\"bar".

^'''));
    });

    test("escapes string backslashes", () {
      expect(() => new StringScanner('').expect('foo\\bar'),
          throwsFormattedError('''
Error on line 1, column 1: expected "foo\\\\bar".

^'''));
    });

    test("prints PERL-style regexps", () {
      expect(() => new StringScanner('').expect(new RegExp(r'foo')),
          throwsFormattedError('''
Error on line 1, column 1: expected /foo/.

^'''));
    });

    test("escape regexp forward slashes", () {
      expect(() => new StringScanner('').expect(new RegExp(r'foo/bar')),
          throwsFormattedError('''
Error on line 1, column 1: expected /foo\\/bar/.

^'''));
    });

    test("does not escape regexp backslashes", () {
      expect(() => new StringScanner('').expect(new RegExp(r'foo\bar')),
          throwsFormattedError('''
Error on line 1, column 1: expected /foo\\bar/.

^'''));
    });
  });
}
