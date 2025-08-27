// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  AssertStatementTest().buildAll();
}

class AssertStatementTest extends PartialCodeTest {
  buildAll() {
    List<String> allExceptEof = PartialCodeTest.statementSuffixes
        .map((t) => t.name)
        .toList();
    buildTests(
      'assert_statement',
      [
        TestDescriptor('keyword', 'assert', [
          ParserErrorCode.expectedToken,
          ParserErrorCode.expectedToken,
        ], "assert (_s_);"),
        TestDescriptor(
          'leftParen',
          'assert (',
          [
            ParserErrorCode.missingIdentifier,
            ScannerErrorCode.expectedToken,
            ParserErrorCode.expectedToken,
          ],
          "assert (_s_);",
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
        TestDescriptor('condition', 'assert (a', [
          ParserErrorCode.expectedToken,
          ScannerErrorCode.expectedToken,
        ], "assert (a);"),
        TestDescriptor(
          'comma',
          'assert (a,',
          [ScannerErrorCode.expectedToken, ParserErrorCode.expectedToken],
          "assert (a,);",
          failing: allExceptEof,
        ),
        TestDescriptor('message', 'assert (a, b', [
          ParserErrorCode.expectedToken,
          ScannerErrorCode.expectedToken,
        ], "assert (a, b);"),
        TestDescriptor('trailingComma', 'assert (a, b,', [
          ParserErrorCode.expectedToken,
          ScannerErrorCode.expectedToken,
        ], "assert (a, b,);"),
        TestDescriptor('rightParen', 'assert (a, b)', [
          ParserErrorCode.expectedToken,
        ], "assert (a, b);"),
      ],
      PartialCodeTest.statementSuffixes,
      head: 'f() { ',
      tail: ' }',
    );
  }
}
