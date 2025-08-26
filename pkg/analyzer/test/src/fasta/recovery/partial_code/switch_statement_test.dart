// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  SwitchStatementTest().buildAll();
}

class SwitchStatementTest extends PartialCodeTest {
  buildAll() {
    var allExceptEof = PartialCodeTest.statementSuffixes
        .map((ts) => ts.name)
        .toList();
    buildTests(
      'switch_statement',
      [
        TestDescriptor(
          'keyword',
          'switch',
          [
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedSwitchStatementBody,
            ParserErrorCode.expectedToken,
          ],
          "switch (_s_) {}",
          failing: ['block'],
        ),
        TestDescriptor(
          'leftParen',
          'switch (',
          [
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedSwitchStatementBody,
            ScannerErrorCode.expectedToken,
          ],
          "switch (_s_) {}",
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
        TestDescriptor(
          'expression',
          'switch (a',
          [
            ParserErrorCode.expectedSwitchStatementBody,
            ScannerErrorCode.expectedToken,
          ],
          "switch (a) {}",
          failing: ['block'],
        ),
        TestDescriptor(
          'rightParen',
          'switch (a)',
          [ParserErrorCode.expectedSwitchStatementBody],
          "switch (a) {}",
          failing: ['block'],
        ),
        TestDescriptor(
          'leftBrace',
          'switch (a) {',
          [ScannerErrorCode.expectedToken],
          "switch (a) {}",
          failing: allExceptEof,
        ),
      ],
      PartialCodeTest.statementSuffixes,
      head: 'f() { ',
      tail: ' }',
    );
  }
}
