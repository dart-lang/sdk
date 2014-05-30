// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library string_scanner.string_scanner_test;

import 'package:string_scanner/string_scanner.dart';
import 'package:unittest/unittest.dart';

void main() {
  group('with an empty string', () {
    var scanner;
    setUp(() {
      scanner = new StringScanner('');
    });

    test('is done', () {
      expect(scanner.isDone, isTrue);
      expect(scanner.expectDone, isNot(throwsFormatException));
    });

    test('rest is empty', () {
      expect(scanner.rest, isEmpty);
    });

    test('lastMatch is null', () {
      expect(scanner.lastMatch, isNull);
    });

    test('position is zero', () {
      expect(scanner.position, equals(0));
    });

    test("readChar fails and doesn't change the state", () {
      expect(scanner.readChar, throwsFormatException);
      expect(scanner.lastMatch, isNull);
      expect(scanner.position, equals(0));
    });

    test("peekChar returns null and doesn't change the state", () {
      expect(scanner.peekChar(), isNull);
      expect(scanner.lastMatch, isNull);
      expect(scanner.position, equals(0));
    });

    test("scan returns false and doesn't change the state", () {
      expect(scanner.scan(new RegExp('.')), isFalse);
      expect(scanner.lastMatch, isNull);
      expect(scanner.position, equals(0));
    });

    test("expect throws a FormatException and doesn't change the state", () {
      expect(() => scanner.expect(new RegExp('.')), throwsFormatException);
      expect(scanner.lastMatch, isNull);
      expect(scanner.position, equals(0));
    });

    test("matches returns false and doesn't change the state", () {
      expect(scanner.matches(new RegExp('.')), isFalse);
      expect(scanner.lastMatch, isNull);
      expect(scanner.position, equals(0));
    });

    test('setting position to 1 throws an ArgumentError', () {
      expect(() {
        scanner.position = 1;
      }, throwsArgumentError);
    });

    test('setting position to -1 throws an ArgumentError', () {
      expect(() {
        scanner.position = -1;
      }, throwsArgumentError);
    });
  });

  group('at the beginning of a string', () {
    var scanner;
    setUp(() {
      scanner = new StringScanner('foo bar');
    });

    test('is not done', () {
      expect(scanner.isDone, isFalse);
      expect(scanner.expectDone, throwsFormatException);
    });

    test('rest is the whole string', () {
      expect(scanner.rest, equals('foo bar'));
    });

    test('lastMatch is null', () {
      expect(scanner.lastMatch, isNull);
    });

    test('position is zero', () {
      expect(scanner.position, equals(0));
    });

    test('readChar returns the first character and moves forward', () {
      expect(scanner.readChar(), equals(0x66));
      expect(scanner.lastMatch, isNull);
      expect(scanner.position, equals(1));
    });

    test('peekChar returns the first character', () {
      expect(scanner.peekChar(), equals(0x66));
      expect(scanner.lastMatch, isNull);
      expect(scanner.position, equals(0));
    });

    test('peekChar with an argument returns the nth character', () {
      expect(scanner.peekChar(4), equals(0x62));
      expect(scanner.lastMatch, isNull);
      expect(scanner.position, equals(0));
    });

    test("a matching scan returns true and changes the state", () {
      expect(scanner.scan(new RegExp('f(..)')), isTrue);
      expect(scanner.lastMatch[1], equals('oo'));
      expect(scanner.position, equals(3));
      expect(scanner.rest, equals(' bar'));
    });

    test("a non-matching scan returns false and sets lastMatch to null", () {
      expect(scanner.matches(new RegExp('f(..)')), isTrue);
      expect(scanner.lastMatch, isNotNull);

      expect(scanner.scan(new RegExp('b(..)')), isFalse);
      expect(scanner.lastMatch, isNull);
      expect(scanner.position, equals(0));
      expect(scanner.rest, equals('foo bar'));
    });

    test("a matching expect changes the state", () {
      scanner.expect(new RegExp('f(..)'));
      expect(scanner.lastMatch[1], equals('oo'));
      expect(scanner.position, equals(3));
      expect(scanner.rest, equals(' bar'));
    });

    test("a non-matching expect throws a FormatException and sets lastMatch to "
        "null", () {
      expect(scanner.matches(new RegExp('f(..)')), isTrue);
      expect(scanner.lastMatch, isNotNull);

      expect(() => scanner.expect(new RegExp('b(..)')), throwsFormatException);
      expect(scanner.lastMatch, isNull);
      expect(scanner.position, equals(0));
      expect(scanner.rest, equals('foo bar'));
    });

    test("a matching matches returns true and only changes lastMatch", () {
      expect(scanner.matches(new RegExp('f(..)')), isTrue);
      expect(scanner.lastMatch[1], equals('oo'));
      expect(scanner.position, equals(0));
      expect(scanner.rest, equals('foo bar'));
    });

    test("a non-matching matches returns false and doesn't change the state",
        () {
      expect(scanner.matches(new RegExp('b(..)')), isFalse);
      expect(scanner.lastMatch, isNull);
      expect(scanner.position, equals(0));
      expect(scanner.rest, equals('foo bar'));
    });

    test('setting position to 1 moves the cursor forward', () {
      scanner.position = 1;
      expect(scanner.position, equals(1));
      expect(scanner.rest, equals('oo bar'));

      expect(scanner.scan(new RegExp('oo.')), isTrue);
      expect(scanner.lastMatch[0], equals('oo '));
      expect(scanner.position, equals(4));
      expect(scanner.rest, equals('bar'));
    });

    test('setting position beyond the string throws an ArgumentError', () {
      expect(() {
        scanner.position = 8;
      }, throwsArgumentError);
    });

    test('setting position to -1 throws an ArgumentError', () {
      expect(() {
        scanner.position = -1;
      }, throwsArgumentError);
    });

    test('scan accepts any Pattern', () {
      expect(scanner.scan('foo'), isTrue);
      expect(scanner.lastMatch[0], equals('foo'));
      expect(scanner.position, equals(3));
      expect(scanner.rest, equals(' bar'));
    });

    test('scans multiple times', () {
      expect(scanner.scan(new RegExp('f(..)')), isTrue);
      expect(scanner.lastMatch[1], equals('oo'));
      expect(scanner.position, equals(3));
      expect(scanner.rest, equals(' bar'));

      expect(scanner.scan(new RegExp(' b(..)')), isTrue);
      expect(scanner.lastMatch[1], equals('ar'));
      expect(scanner.position, equals(7));
      expect(scanner.rest, equals(''));
      expect(scanner.isDone, isTrue);
      expect(scanner.expectDone, isNot(throwsFormatException));
    });
  });

  group('at the end of a string', () {
    var scanner;
    setUp(() {
      scanner = new StringScanner('foo bar');
      expect(scanner.scan('foo bar'), isTrue);
    });

    test('is done', () {
      expect(scanner.isDone, isTrue);
      expect(scanner.expectDone, isNot(throwsFormatException));
    });

    test('rest is empty', () {
      expect(scanner.rest, isEmpty);
    });

    test('position is zero', () {
      expect(scanner.position, equals(7));
    });

    test("readChar fails and doesn't change the state", () {
      expect(scanner.readChar, throwsFormatException);
      expect(scanner.lastMatch, isNotNull);
      expect(scanner.position, equals(7));
    });

    test("peekChar returns null and doesn't change the state", () {
      expect(scanner.peekChar(), isNull);
      expect(scanner.lastMatch, isNotNull);
      expect(scanner.position, equals(7));
    });

    test("scan returns false and sets lastMatch to null", () {
      expect(scanner.scan(new RegExp('.')), isFalse);
      expect(scanner.lastMatch, isNull);
      expect(scanner.position, equals(7));
    });

    test("expect throws a FormatException and sets lastMatch to null", () {
      expect(() => scanner.expect(new RegExp('.')), throwsFormatException);
      expect(scanner.lastMatch, isNull);
      expect(scanner.position, equals(7));
    });

    test("matches returns false sets lastMatch to null", () {
      expect(scanner.matches(new RegExp('.')), isFalse);
      expect(scanner.lastMatch, isNull);
      expect(scanner.position, equals(7));
    });

    test('setting position to 1 moves the cursor backward', () {
      scanner.position = 1;
      expect(scanner.position, equals(1));
      expect(scanner.rest, equals('oo bar'));

      expect(scanner.scan(new RegExp('oo.')), isTrue);
      expect(scanner.lastMatch[0], equals('oo '));
      expect(scanner.position, equals(4));
      expect(scanner.rest, equals('bar'));
    });

    test('setting position beyond the string throws an ArgumentError', () {
      expect(() {
        scanner.position = 8;
      }, throwsArgumentError);
    });

    test('setting position to -1 throws an ArgumentError', () {
      expect(() {
        scanner.position = -1;
      }, throwsArgumentError);
    });
  });

  group('a scanner constructed with a custom position', () {
    test('starts scanning from that position', () {
      var scanner = new StringScanner('foo bar', position: 1);
      expect(scanner.position, equals(1));
      expect(scanner.rest, equals('oo bar'));

      expect(scanner.scan(new RegExp('oo.')), isTrue);
      expect(scanner.lastMatch[0], equals('oo '));
      expect(scanner.position, equals(4));
      expect(scanner.rest, equals('bar'));
    });

    test('throws an ArgumentError if the position is -1', () {
      expect(() => new StringScanner('foo bar', position: -1),
          throwsArgumentError);
    });

    test('throws an ArgumentError if the position is beyond the string', () {
      expect(() => new StringScanner('foo bar', position: 8),
          throwsArgumentError);
    });
  });
}
