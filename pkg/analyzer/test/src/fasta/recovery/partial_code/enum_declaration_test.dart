// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new EnumDeclarationTest().buildAll();
}

class EnumDeclarationTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'enum_declaration',
        [
          new TestDescriptor(
              'keyword',
              'enum',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.MISSING_ENUM_BODY
              ],
              'enum _s_ {}',
              expectedErrorsInValidCode: [ParserErrorCode.EMPTY_ENUM_BODY],
              failing: ['functionNonVoid', 'getter']),
          new TestDescriptor('name', 'enum E',
              [ParserErrorCode.MISSING_ENUM_BODY], 'enum E {}',
              expectedErrorsInValidCode: [ParserErrorCode.EMPTY_ENUM_BODY]),
          new TestDescriptor(
              'missingName',
              'enum {}',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EMPTY_ENUM_BODY
              ],
              'enum _s_ {}',
              expectedErrorsInValidCode: [ParserErrorCode.EMPTY_ENUM_BODY]),
          new TestDescriptor(
              'leftBrace',
              'enum E {',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ScannerErrorCode.EXPECTED_TOKEN
              ],
              'enum E {_s_}',
              failing: [
                'eof' /* tested separately below */,
                'typedef',
                'functionNonVoid',
                'getter',
                'setter'
              ]),
          new TestDescriptor(
              'comma',
              'enum E {,',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.MISSING_IDENTIFIER,
                ScannerErrorCode.EXPECTED_TOKEN
              ],
              'enum E {_s_,_s_}',
              failing: [
                'eof' /* tested separately below */,
                'typedef',
                'functionNonVoid',
                'getter',
                'setter'
              ]),
          new TestDescriptor('value', 'enum E {a',
              [ScannerErrorCode.EXPECTED_TOKEN], 'enum E {a}'),
          new TestDescriptor(
              'commaValue',
              'enum E {,a',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ScannerErrorCode.EXPECTED_TOKEN
              ],
              'enum E {_s_, a}'),
          new TestDescriptor('commaRightBrace', 'enum E {,}',
              [ParserErrorCode.MISSING_IDENTIFIER], 'enum E {_s_}'),
          new TestDescriptor('commaValueRightBrace', 'enum E {, a}',
              [ParserErrorCode.MISSING_IDENTIFIER], 'enum E {_s_, a}'),
        ],
        PartialCodeTest.declarationSuffixes);
    buildTests('enum_eof', [
      new TestDescriptor(
          'leftBrace',
          'enum E {',
          [ParserErrorCode.EMPTY_ENUM_BODY, ScannerErrorCode.EXPECTED_TOKEN],
          'enum E {}',
          expectedErrorsInValidCode: [ParserErrorCode.EMPTY_ENUM_BODY]),
      new TestDescriptor(
          'comma',
          'enum E {,',
          [ParserErrorCode.MISSING_IDENTIFIER, ScannerErrorCode.EXPECTED_TOKEN],
          'enum E {_s_}'),
    ], []);
  }
}
