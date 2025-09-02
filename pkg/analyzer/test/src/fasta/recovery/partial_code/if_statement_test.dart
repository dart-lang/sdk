// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  IfStatementTest().buildAll();
}

class IfStatementTest extends PartialCodeTest {
  buildAll() {
    buildTests(
      'if_statement',
      [
        TestDescriptor('keyword', 'if', [
          ParserErrorCode.missingIdentifier,
          ParserErrorCode.expectedToken,
        ], "if (_s_)"),
        TestDescriptor(
          'leftParen',
          'if (',
          [ParserErrorCode.missingIdentifier, ScannerErrorCode.expectedToken],
          "if (_s_)",
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
        TestDescriptor('condition', 'if (a', [
          ScannerErrorCode.expectedToken,
        ], "if (a)"),
      ],
      PartialCodeTest.statementSuffixes,
      head: 'f() { ',
      includeEof: false,
      tail: ' }',
    );
    buildTests(
      'if_statement',
      [
        TestDescriptor(
          'keyword',
          'if',
          [
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
          "if (_s_);",
          allFailing: true,
        ),
        TestDescriptor(
          'leftParen',
          'if (',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
          "if (_s_);",
          allFailing: true,
        ),
        TestDescriptor(
          'condition',
          'if (a',
          [ParserErrorCode.expectedToken],
          "if (a);",
          allFailing: true,
        ),
      ],
      [],
      head: 'f() { ',
      tail: ' }',
    );
  }
}
