// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  ForStatementTest().buildAll();
}

class ForStatementTest extends PartialCodeTest {
  buildAll() {
    List<String> allExceptEof = PartialCodeTest.statementSuffixes
        .map((t) => t.name)
        .toList();
    buildTests(
      'for_statement',
      [
        TestDescriptor('keyword', 'for', [
          ParserErrorCode.expectedToken,
        ], 'for (;;) _s_;'),
        TestDescriptor(
          'emptyParen',
          'for ()',
          [
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
          "for (_s_;_s_;) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'leftParen',
          'for (',
          [
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
            ScannerErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
          "for (_s_;_s_;) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'var',
          'for (var',
          [
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
            ParserErrorCode.expectedToken,
            ParserErrorCode.expectedToken,
            ParserErrorCode.expectedToken,
          ],
          "for (var _s_;;) _s_;",
          allFailing: true,
        ),
        TestDescriptor(
          'varAndIdentifier',
          'for (var i',
          [
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
            ScannerErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
          "for (var i;_s_;) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'equals',
          'for (var i =',
          [
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
            ScannerErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
          "for (var i = _s_;_s_;) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'initializer',
          'for (var i = 0',
          [
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
            ScannerErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
          "for (var i = 0;_s_;) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'firstSemicolon',
          'for (var i = 0;',
          [
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
            ScannerErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
          "for (var i = 0;_s_;) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'secondSemicolon',
          'for (var i = 0;;',
          [
            ScannerErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
          "for (var i = 0;;) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'rightParen',
          'for (var i = 0;;)',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
          "for (var i = 0;;) _s_;",
          failing: allExceptEof,
        ),
      ],
      PartialCodeTest.statementSuffixes,
      head: 'f() { ',
      tail: ' }',
    );
  }
}
