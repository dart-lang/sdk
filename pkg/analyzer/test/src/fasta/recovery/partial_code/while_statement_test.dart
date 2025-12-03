// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;

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
            diag.expectedToken,
            diag.missingIdentifier,
            diag.missingIdentifier,
            diag.expectedToken,
          ],
          "while (_s_)",
          expectedDiagnosticsInValidCode: [
            diag.missingIdentifier,
            diag.expectedToken,
          ],
        ),
        TestDescriptor(
          'leftParen',
          'while (',
          [
            diag.expectedToken,
            diag.missingIdentifier,
            diag.missingIdentifier,
            diag.expectedToken,
          ],
          "while (_s_)",
          expectedDiagnosticsInValidCode: [
            diag.missingIdentifier,
            diag.expectedToken,
          ],
        ),
        TestDescriptor(
          'condition',
          'while (a',
          [diag.expectedToken, diag.missingIdentifier, diag.expectedToken],
          "while (a)",
          expectedDiagnosticsInValidCode: [
            diag.missingIdentifier,
            diag.expectedToken,
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
          [diag.missingIdentifier, diag.expectedToken],
          "while (_s_)",
          failing: ['break', 'continue'],
        ),
        TestDescriptor(
          'leftParen',
          'while (',
          [diag.missingIdentifier, diag.expectedToken],
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
          [diag.expectedToken],
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
