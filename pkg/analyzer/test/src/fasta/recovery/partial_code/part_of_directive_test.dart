// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new PartOfDirectivesTest().buildAll();
}

class PartOfDirectivesTest extends PartialCodeTest {
  buildAll() {
    List<String> allExceptEof = <String>[
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
        'part_of_directive',
        [
          new TestDescriptor(
              'keyword',
              'part of',
              [
                ParserErrorCode.MISSING_NAME_IN_PART_OF_DIRECTIVE,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              'part of _s_;',
              allFailing: true),
          new TestDescriptor('name', 'part of lib',
              [ParserErrorCode.EXPECTED_TOKEN], 'library lib;',
              allFailing: true),
          new TestDescriptor(
              'nameDot',
              'part of lib.',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              'part of lib._s_;',
              failing: allExceptEof),
          new TestDescriptor('nameDotName', 'part of lib.a',
              [ParserErrorCode.EXPECTED_TOKEN], 'part of lib.a;',
              failing: onlyConstAndFinal),
          new TestDescriptor('emptyUri', "part of ''",
              [ParserErrorCode.EXPECTED_TOKEN], "part of '';",
              failing: onlyConstAndFinal),
          new TestDescriptor('uri', "part of 'a.dart'",
              [ParserErrorCode.EXPECTED_TOKEN], "part of 'a.dart';",
              failing: onlyConstAndFinal),
        ],
        PartialCodeTest.declarationSuffixes);
  }
}
