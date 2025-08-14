// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  WhileStatementTest().buildAll();
}

class WhileStatementTest extends PartialCodeTest {
  buildAll() {
    buildTests(
      'while_statement',
      <TestDescriptor>[
        TestDescriptor(
          'keyword',
          'while',
          [
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
          "while (_s_)",
          expectedDiagnosticsInValidCode: [
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
        ),
        TestDescriptor(
          'leftParen',
          'while (',
          [
            ScannerErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
          "while (_s_)",
          expectedDiagnosticsInValidCode: [
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
        ),
        TestDescriptor(
          'condition',
          'while (a',
          [
            ScannerErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
          "while (a)",
          expectedDiagnosticsInValidCode: [
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
        ),
      ],
      [],
      head: 'f() { ',
      tail: ' }',
    );
    buildTests(
      'while_statement',
      <TestDescriptor>[
        TestDescriptor(
          'keyword',
          'while',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
          "while (_s_)",
          failing: ['break', 'continue'],
        ),
        TestDescriptor(
          'leftParen',
          'while (',
          [ParserErrorCode.missingIdentifier, ScannerErrorCode.expectedToken],
          "while (_s_)",
          failing: [
            'assert',
            'block',
            'break',
            'continue',
            'labeled',
            'localFunctionNonVoid',
            'localFunctionVoid',
            'return',
            'switch',
          ],
        ),
        TestDescriptor(
          'condition',
          'while (a',
          [ScannerErrorCode.expectedToken],
          "while (a)",
          failing: ['break', 'continue'],
        ),
      ],
      PartialCodeTest.statementSuffixes,
      head: 'f() { ',
      includeEof: false,
      tail: ' }',
    );
  }
}
