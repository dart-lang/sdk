// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  DoStatementTest().buildAll();
}

class DoStatementTest extends PartialCodeTest {
  final allExceptEof = PartialCodeTest.statementSuffixes
      .map((ts) => ts.name)
      .toList();
  buildAll() {
    buildTests(
      'do_statement',
      [
        TestDescriptor(
          'keyword',
          'do',
          [
            ParserErrorCode.expectedToken,
            ParserErrorCode.expectedToken,
            ParserErrorCode.expectedToken,
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
            ParserErrorCode.expectedToken,
          ],
          "do {} while (_s_);",
          allFailing: true,
        ),
        TestDescriptor(
          'leftBrace',
          'do {',
          [
            ScannerErrorCode.expectedToken,
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
            ParserErrorCode.expectedToken,
          ],
          "do {} while (_s_);",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'rightBrace',
          'do {}',
          [
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
            ParserErrorCode.expectedToken,
          ],
          "do {} while (_s_);",
          failing: ['while'],
        ),
        TestDescriptor('while', 'do {} while', [
          ParserErrorCode.expectedToken,
          ParserErrorCode.missingIdentifier,
          ParserErrorCode.expectedToken,
        ], "do {} while (_s_);"),
        TestDescriptor(
          'leftParen',
          'do {} while (',
          [
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
            ScannerErrorCode.expectedToken,
          ],
          "do {} while (_s_);",
          failing: [
            'assert',
            'block',
            'labeled',
            'localFunctionNonVoid',
            'localFunctionVoid',
            'return',
            'switch',
          ],
        ),
        TestDescriptor('condition', 'do {} while (a', [
          ParserErrorCode.expectedToken,
          ScannerErrorCode.expectedToken,
        ], "do {} while (a);"),
        TestDescriptor('rightParen', 'do {} while (a)', [
          ParserErrorCode.expectedToken,
        ], "do {} while (a);"),
      ],
      PartialCodeTest.statementSuffixes,
      head: 'f() { ',
      tail: ' }',
    );
  }
}
