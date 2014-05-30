// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library string_scanner.line_scanner_test;

import 'package:string_scanner/string_scanner.dart';
import 'package:unittest/unittest.dart';

void main() {
  var scanner;
  setUp(() {
    scanner = new LineScanner('foo\nbar\nbaz');
  });

  test('begins with line and column 0', () {
    expect(scanner.line, equals(0));
    expect(scanner.column, equals(0));
  });

  group("scan()", () {
    test("consuming no newlines increases the column but not the line", () {
      scanner.scan('foo');
      expect(scanner.line, equals(0));
      expect(scanner.column, equals(3));
    });

    test("consuming a newline resets the column and increases the line", () {
      scanner.expect('foo\nba');
      expect(scanner.line, equals(1));
      expect(scanner.column, equals(2));
    });

    test("consuming multiple newlines resets the column and increases the line",
        () {
      scanner.expect('foo\nbar\nb');
      expect(scanner.line, equals(2));
      expect(scanner.column, equals(1));
    });
  });

  group("readChar()", () {
    test("on a non-newline character increases the column but not the line",
        () {
      scanner.readChar();
      expect(scanner.line, equals(0));
      expect(scanner.column, equals(1));
    });

    test("consuming a newline resets the column and increases the line", () {
      scanner.expect('foo');
      expect(scanner.line, equals(0));
      expect(scanner.column, equals(3));

      scanner.readChar();
      expect(scanner.line, equals(1));
      expect(scanner.column, equals(0));
    });
  });

  group("position=", () {
    test("forward through newlines sets the line and column", () {
      scanner.position = 9; // "foo\nbar\nb"
      expect(scanner.line, equals(2));
      expect(scanner.column, equals(1));
    });

    test("forward through no newlines sets the column", () {
      scanner.position = 2; // "fo"
      expect(scanner.line, equals(0));
      expect(scanner.column, equals(2));
    });

    test("backward through newlines sets the line and column", () {
      scanner.scan("foo\nbar\nbaz");
      scanner.position = 2; // "fo"
      expect(scanner.line, equals(0));
      expect(scanner.column, equals(2));
    });

    test("backward through no newlines sets the column", () {
      scanner.scan("foo\nbar\nbaz");
      scanner.position = 9; // "foo\nbar\nb"
      expect(scanner.line, equals(2));
      expect(scanner.column, equals(1));
    });
  });

  test("state= restores the line, column, and position", () {
    scanner.scan('foo\nb');
    var state = scanner.state;

    scanner.scan('ar\nba');
    scanner.state = state;
    expect(scanner.rest, equals('ar\nbaz'));
    expect(scanner.line, equals(1));
    expect(scanner.column, equals(1));
  });

  test("state= rejects a foreign state", () {
    scanner.scan('foo\nb');

    expect(() => new LineScanner(scanner.string).state = scanner.state,
        throwsArgumentError);
  });
}
