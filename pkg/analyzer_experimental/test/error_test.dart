// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:unittest/unittest.dart';

import 'utils.dart';

void main() {
  test("a valid Dart file doesn't throw any errors", () {
    expect(
        errorsForFile('void main() => print("Hello, world!");'),
        isNull);
  });

  test("an error on the first line", () {
    expect(errorsForFile('void foo;\n'),
        equals('Error on line 1 of test.dart: ...\n'
               'void foo;\n'
               '^^^^\n'));
  });

  test("an error on the last line", () {
    expect(errorsForFile('\nvoid foo;'),
        equals('Error on line 2 of test.dart: ...\n'
               'void foo;\n'
               '^^^^\n'));
  });

  test("an error in the middle", () {
    expect(errorsForFile('\nvoid foo;\n'),
        equals('Error on line 2 of test.dart: ...\n'
               'void foo;\n'
               '^^^^\n'));
  });

  var veryLongString = new List.filled(107, ' ').join('');

  test("an error at the end of a very long line", () {
    expect(errorsForFile('$veryLongString     void foo;'),
        equals('Error on line 1 of test.dart: ...\n'
               '...$veryLongString void foo;\n'
               '$veryLongString    ^^^^\n'));
  });

  test("an error at the beginning of a very long line", () {
    expect(errorsForFile('void foo;     $veryLongString'),
        equals('Error on line 1 of test.dart: ...\n'
               'void foo; $veryLongString...\n'
               '^^^^\n'));
  });

  test("an error in the middle of a very long line", () {
    expect(errorsForFile('$veryLongString void foo;$veryLongString'),
        equals('Error on line 1 of test.dart: ...\n'
               '...                                                         '
                   'void foo;                                                '
                   '...\n'
               '                                                            '
                   '^^^^\n'));
  });
}
