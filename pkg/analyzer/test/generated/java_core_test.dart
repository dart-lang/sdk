// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.java_core_test;

import 'package:analyzer/src/generated/java_core.dart';
import 'package:unittest/unittest.dart';

main() {
  group('Character', () {
    group('isDigit', () {
      test('digits', () {
        expect(Character.isDigit('0'.codeUnitAt(0)), isTrue);
        expect(Character.isDigit('1'.codeUnitAt(0)), isTrue);
        expect(Character.isDigit('9'.codeUnitAt(0)), isTrue);
      });

      test('letters', () {
        expect(Character.isDigit('a'.codeUnitAt(0)), isFalse);
        expect(Character.isDigit('b'.codeUnitAt(0)), isFalse);
        expect(Character.isDigit('z'.codeUnitAt(0)), isFalse);
        expect(Character.isDigit('C'.codeUnitAt(0)), isFalse);
        expect(Character.isDigit('D'.codeUnitAt(0)), isFalse);
        expect(Character.isDigit('Y'.codeUnitAt(0)), isFalse);
      });

      test('other', () {
        expect(Character.isDigit(' '.codeUnitAt(0)), isFalse);
        expect(Character.isDigit('.'.codeUnitAt(0)), isFalse);
        expect(Character.isDigit('-'.codeUnitAt(0)), isFalse);
        expect(Character.isDigit('+'.codeUnitAt(0)), isFalse);
      });
    });

    group('isLetter', () {
      test('digits', () {
        expect(Character.isLetter('0'.codeUnitAt(0)), isFalse);
        expect(Character.isLetter('1'.codeUnitAt(0)), isFalse);
        expect(Character.isLetter('9'.codeUnitAt(0)), isFalse);
      });

      test('letters', () {
        expect(Character.isLetter('a'.codeUnitAt(0)), isTrue);
        expect(Character.isLetter('b'.codeUnitAt(0)), isTrue);
        expect(Character.isLetter('z'.codeUnitAt(0)), isTrue);
        expect(Character.isLetter('C'.codeUnitAt(0)), isTrue);
        expect(Character.isLetter('D'.codeUnitAt(0)), isTrue);
        expect(Character.isLetter('Y'.codeUnitAt(0)), isTrue);
      });

      test('other', () {
        expect(Character.isLetter(' '.codeUnitAt(0)), isFalse);
        expect(Character.isLetter('.'.codeUnitAt(0)), isFalse);
        expect(Character.isLetter('-'.codeUnitAt(0)), isFalse);
        expect(Character.isLetter('+'.codeUnitAt(0)), isFalse);
      });
    });

    group('isLetterOrDigit', () {
      test('digits', () {
        expect(Character.isLetterOrDigit('0'.codeUnitAt(0)), isTrue);
        expect(Character.isLetterOrDigit('1'.codeUnitAt(0)), isTrue);
        expect(Character.isLetterOrDigit('9'.codeUnitAt(0)), isTrue);
      });

      test('letters', () {
        expect(Character.isLetterOrDigit('a'.codeUnitAt(0)), isTrue);
        expect(Character.isLetterOrDigit('b'.codeUnitAt(0)), isTrue);
        expect(Character.isLetterOrDigit('z'.codeUnitAt(0)), isTrue);
        expect(Character.isLetterOrDigit('C'.codeUnitAt(0)), isTrue);
        expect(Character.isLetterOrDigit('D'.codeUnitAt(0)), isTrue);
        expect(Character.isLetterOrDigit('Y'.codeUnitAt(0)), isTrue);
      });

      test('other', () {
        expect(Character.isLetterOrDigit(' '.codeUnitAt(0)), isFalse);
        expect(Character.isLetterOrDigit('.'.codeUnitAt(0)), isFalse);
        expect(Character.isLetterOrDigit('-'.codeUnitAt(0)), isFalse);
        expect(Character.isLetterOrDigit('+'.codeUnitAt(0)), isFalse);
      });
    });

    group('isLowerCase', () {
      test('ASCII digits', () {
        expect(Character.isLowerCase('0'.codeUnitAt(0)), isFalse);
        expect(Character.isLowerCase('9'.codeUnitAt(0)), isFalse);
      });

      test('ASCII lower', () {
        expect(Character.isLowerCase('a'.codeUnitAt(0)), isTrue);
        expect(Character.isLowerCase('s'.codeUnitAt(0)), isTrue);
        expect(Character.isLowerCase('z'.codeUnitAt(0)), isTrue);
      });

      test('ASCII upper', () {
        expect(Character.isLowerCase('A'.codeUnitAt(0)), isFalse);
        expect(Character.isLowerCase('S'.codeUnitAt(0)), isFalse);
        expect(Character.isLowerCase('Z'.codeUnitAt(0)), isFalse);
      });
    });

    group('isUpperCase', () {
      test('ASCII digits', () {
        expect(Character.isUpperCase('0'.codeUnitAt(0)), isFalse);
        expect(Character.isUpperCase('9'.codeUnitAt(0)), isFalse);
      });

      test('ASCII lower', () {
        expect(Character.isUpperCase('a'.codeUnitAt(0)), isFalse);
        expect(Character.isUpperCase('s'.codeUnitAt(0)), isFalse);
        expect(Character.isUpperCase('z'.codeUnitAt(0)), isFalse);
      });

      test('ASCII upper', () {
        expect(Character.isUpperCase('A'.codeUnitAt(0)), isTrue);
        expect(Character.isUpperCase('S'.codeUnitAt(0)), isTrue);
        expect(Character.isUpperCase('Z'.codeUnitAt(0)), isTrue);
      });
    });

    test('toLowerCase', () {
      expect(Character.toLowerCase('A'.codeUnitAt(0)), 'a'.codeUnitAt(0));
      expect(Character.toLowerCase('B'.codeUnitAt(0)), 'b'.codeUnitAt(0));
      expect(Character.toLowerCase('Z'.codeUnitAt(0)), 'z'.codeUnitAt(0));
      expect(Character.toLowerCase('c'.codeUnitAt(0)), 'c'.codeUnitAt(0));
      expect(Character.toLowerCase('0'.codeUnitAt(0)), '0'.codeUnitAt(0));
    });

    test('toUpperCase', () {
      expect(Character.toUpperCase('a'.codeUnitAt(0)), 'A'.codeUnitAt(0));
      expect(Character.toUpperCase('b'.codeUnitAt(0)), 'B'.codeUnitAt(0));
      expect(Character.toUpperCase('z'.codeUnitAt(0)), 'Z'.codeUnitAt(0));
      expect(Character.toUpperCase('C'.codeUnitAt(0)), 'C'.codeUnitAt(0));
      expect(Character.toUpperCase('0'.codeUnitAt(0)), '0'.codeUnitAt(0));
    });

    test('isWhitespace', () {
      expect(Character.isWhitespace('\t'.codeUnitAt(0)), isTrue);
      expect(Character.isWhitespace(' '.codeUnitAt(0)), isTrue);
      expect(Character.isWhitespace('\n'.codeUnitAt(0)), isTrue);
      expect(Character.isWhitespace('\r'.codeUnitAt(0)), isTrue);
      expect(Character.isWhitespace('.'.codeUnitAt(0)), isFalse);
      expect(Character.isWhitespace('0'.codeUnitAt(0)), isFalse);
      expect(Character.isWhitespace('9'.codeUnitAt(0)), isFalse);
      expect(Character.isWhitespace('a'.codeUnitAt(0)), isFalse);
      expect(Character.isWhitespace('z'.codeUnitAt(0)), isFalse);
      expect(Character.isWhitespace('A'.codeUnitAt(0)), isFalse);
      expect(Character.isWhitespace('Z'.codeUnitAt(0)), isFalse);
    });
  });
}