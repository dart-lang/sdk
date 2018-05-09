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
    List<String> allExceptEof = PartialCodeTest.declarationSuffixes
        .map((TestSuffix t) => t.name)
        .toList();
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
        ],
        PartialCodeTest.declarationSuffixes);
  }
}
