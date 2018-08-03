// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.test.error;

import 'package:test/test.dart';

import 'utils.dart';

const badDeclaration = 'var int foo;';
const badDeclarationMessage = 'Error in test.dart: '
    'Variables can\'t be declared using both \'var\' and a type name.\n';

void main() {
  group('error', () {
    test("a valid Dart file doesn't throw any errors", () {
      expect(errorsForFile('void main() => print("Hello, world!");'), isNull);
    });

    test("an empty Dart file doesn't throw any errors", () {
      expect(errorsForFile(''), isNull);
    });

    test("an error on the first line", () {
      expect(errorsForFile('$badDeclaration\n'), equals(badDeclarationMessage));
    });

    test("an error on the last line", () {
      expect(errorsForFile('\n$badDeclaration'), equals(badDeclarationMessage));
    });

    test("an error in the middle", () {
      expect(
          errorsForFile('\n$badDeclaration\n'), equals(badDeclarationMessage));
    });

    var veryLongString = new List.filled(107, ' ').join('');

    test("an error at the end of a very long line", () {
      expect(errorsForFile('$veryLongString     $badDeclaration'),
          equals(badDeclarationMessage));
    });

    test("an error at the beginning of a very long line", () {
      expect(errorsForFile('$badDeclaration     $veryLongString'),
          equals(badDeclarationMessage));
    });

    test("an error in the middle of a very long line", () {
      expect(errorsForFile('$veryLongString $badDeclaration$veryLongString'),
          equals(badDeclarationMessage));
    });
  });
}
