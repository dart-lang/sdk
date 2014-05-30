// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library string_scanner.error_test;

import 'package:string_scanner/string_scanner.dart';
import 'package:unittest/unittest.dart';

import 'utils.dart';

void main() {
  test('defaults to the last match', () {
    var scanner = new StringScanner('foo bar baz');
    scanner.expect('foo ');
    scanner.expect('bar');
    expect(() => scanner.error('oh no!'), throwsStringScannerException('bar'));
  });

  group("with match", () {
    test('supports an earlier match', () {
      var scanner = new StringScanner('foo bar baz');
      scanner.expect('foo ');
      var match = scanner.lastMatch;
      scanner.expect('bar');
      expect(() => scanner.error('oh no!', match: match),
          throwsStringScannerException('foo '));
    });

    test('supports a match on a previous line', () {
      var scanner = new StringScanner('foo bar baz\ndo re mi\nearth fire water');
      scanner.expect('foo bar baz\ndo ');
      scanner.expect('re');
      var match = scanner.lastMatch;
      scanner.expect(' mi\nearth ');
      expect(() => scanner.error('oh no!', match: match),
          throwsStringScannerException('re'));
    });

    test('supports a multiline match', () {
      var scanner = new StringScanner('foo bar baz\ndo re mi\nearth fire water');
      scanner.expect('foo bar ');
      scanner.expect('baz\ndo');
      var match = scanner.lastMatch;
      scanner.expect(' re mi');
      expect(() => scanner.error('oh no!', match: match),
          throwsStringScannerException('baz\ndo'));
    });

    test('supports a match after position', () {
      var scanner = new StringScanner('foo bar baz');
      scanner.expect('foo ');
      scanner.expect('bar');
      var match = scanner.lastMatch;
      scanner.position = 0;
      expect(() => scanner.error('oh no!', match: match),
          throwsStringScannerException('bar'));
    });
  });

  group("with position and/or length", () {
    test('defaults to length 1', () {
      var scanner = new StringScanner('foo bar baz');
      scanner.expect('foo ');
      expect(() => scanner.error('oh no!', position: 1),
          throwsStringScannerException('o'));
    });

    test('defaults to the current position', () {
      var scanner = new StringScanner('foo bar baz');
      scanner.expect('foo ');
      expect(() => scanner.error('oh no!', length: 3),
          throwsStringScannerException('bar'));
    });

    test('supports an earlier position', () {
      var scanner = new StringScanner('foo bar baz');
      scanner.expect('foo ');
      expect(() => scanner.error('oh no!', position: 1, length: 2),
          throwsStringScannerException('oo'));
    });

    test('supports a position on a previous line', () {
      var scanner = new StringScanner('foo bar baz\ndo re mi\nearth fire water');
      scanner.expect('foo bar baz\ndo re mi\nearth');
      expect(() => scanner.error('oh no!', position: 15, length: 2),
          throwsStringScannerException('re'));
    });

    test('supports a multiline length', () {
      var scanner = new StringScanner('foo bar baz\ndo re mi\nearth fire water');
      scanner.expect('foo bar baz\ndo re mi\nearth');
      expect(() => scanner.error('oh no!', position: 8, length: 8),
          throwsStringScannerException('baz\ndo r'));
    });

    test('supports a position after the current one', () {
      var scanner = new StringScanner('foo bar baz');
      expect(() => scanner.error('oh no!', position: 4, length: 3),
          throwsStringScannerException('bar'));
    });

    test('supports a length of zero', () {
      var scanner = new StringScanner('foo bar baz');
      expect(() => scanner.error('oh no!', position: 4, length: 0),
          throwsStringScannerException(''));
    });
  });

  group("argument errors", () {
    var scanner;
    setUp(() {
      scanner = new StringScanner('foo bar baz');
      scanner.scan('foo');
    });

    test("if match is passed with position", () {
      expect(
          () => scanner.error("oh no!", match: scanner.lastMatch, position: 1),
          throwsArgumentError);
    });

    test("if match is passed with length", () {
      expect(
          () => scanner.error("oh no!", match: scanner.lastMatch, length: 1),
          throwsArgumentError);
    });

    test("if position is negative", () {
      expect(() => scanner.error("oh no!", position: -1), throwsArgumentError);
    });

    test("if position is outside the string", () {
      expect(() => scanner.error("oh no!", position: 100), throwsArgumentError);
    });

    test("if position + length is outside the string", () {
      expect(() => scanner.error("oh no!", position: 7, length: 7),
          throwsArgumentError);
    });

    test("if length is negative", () {
      expect(() => scanner.error("oh no!", length: -1), throwsArgumentError);
    });
  });
}
