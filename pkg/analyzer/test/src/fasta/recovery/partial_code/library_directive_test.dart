// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new LibraryDirectivesTest().buildAll();
}

class LibraryDirectivesTest extends PartialCodeTest {
  buildAll() {
    List<String> allExceptEof = <String>[
      'import',
      'export',
      'part',
      'class',
      'typedef',
      'functionVoid',
      'functionNonVoid',
      'var',
      'const',
      'final',
      'getter',
      'setter'
    ];
    List<String> onlyConstAndFinal = <String>['const', 'final'];
    buildTests(
        'library_directive',
        [
          new TestDescriptor(
              'keyword',
              'library',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              'library _s_;',
              failing: allExceptEof),
          new TestDescriptor('name', 'library lib',
              [ParserErrorCode.EXPECTED_TOKEN], 'library lib;',
              failing: onlyConstAndFinal),
          new TestDescriptor(
              'nameDot',
              'library lib.',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              'library lib._s_;',
              failing: allExceptEof),
          new TestDescriptor('nameDotName', 'library lib.a',
              [ParserErrorCode.EXPECTED_TOKEN], 'library lib.a;',
              failing: onlyConstAndFinal),
        ],
        PartialCodeTest.prePartSuffixes);
  }
}
