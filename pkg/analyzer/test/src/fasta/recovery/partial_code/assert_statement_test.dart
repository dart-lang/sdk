// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new AssertStatementTest().buildAll();
}

class AssertStatementTest extends PartialCodeTest {
  buildAll() {
    List<String> allExceptEof =
        PartialCodeTest.statementSuffixes.map((t) => t.name).toList();
    buildTests(
        'assert_statement',
        [
          new TestDescriptor(
              'keyword',
              'assert',
              [ParserErrorCode.EXPECTED_TOKEN, ParserErrorCode.EXPECTED_TOKEN],
              "assert (_s_);"),
          new TestDescriptor(
              'leftParen',
              'assert (',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ScannerErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "assert (_s_);",
              failing: [
                'assert',
                'block',
                'labeled',
                'localFunctionNonVoid',
                'localFunctionVoid',
                'return'
              ]),
          new TestDescriptor(
              'condition',
              'assert (a',
              [ParserErrorCode.EXPECTED_TOKEN, ScannerErrorCode.EXPECTED_TOKEN],
              "assert (a);"),
          new TestDescriptor(
              'comma',
              'assert (a,',
              [ScannerErrorCode.EXPECTED_TOKEN, ParserErrorCode.EXPECTED_TOKEN],
              "assert (a,);",
              failing: allExceptEof),
          new TestDescriptor(
              'message',
              'assert (a, b',
              [ParserErrorCode.EXPECTED_TOKEN, ScannerErrorCode.EXPECTED_TOKEN],
              "assert (a, b);"),
          new TestDescriptor(
              'trailingComma',
              'assert (a, b,',
              [ParserErrorCode.EXPECTED_TOKEN, ScannerErrorCode.EXPECTED_TOKEN],
              "assert (a, b,);"),
          new TestDescriptor('rightParen', 'assert (a, b)',
              [ParserErrorCode.EXPECTED_TOKEN], "assert (a, b);"),
        ],
        PartialCodeTest.statementSuffixes,
        head: 'f() { ',
        tail: ' }');
  }
}
