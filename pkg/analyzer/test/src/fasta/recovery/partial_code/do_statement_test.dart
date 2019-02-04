// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new DoStatementTest().buildAll();
}

class DoStatementTest extends PartialCodeTest {
  final allExceptEof =
      PartialCodeTest.statementSuffixes.map((ts) => ts.name).toList();
  buildAll() {
    buildTests(
        'do_statement',
        [
          new TestDescriptor(
              'keyword',
              'do',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "do {} while (_s_);",
              allFailing: true),
          new TestDescriptor(
              'leftBrace',
              'do {',
              [
                ScannerErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "do {} while (_s_);",
              failing: allExceptEof),
          new TestDescriptor(
              'rightBrace',
              'do {}',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "do {} while (_s_);",
              failing: ['while']),
          new TestDescriptor(
              'while',
              'do {} while',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "do {} while (_s_);"),
          new TestDescriptor(
              'leftParen',
              'do {} while (',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ScannerErrorCode.EXPECTED_TOKEN
              ],
              "do {} while (_s_);",
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
              'do {} while (a',
              [ParserErrorCode.EXPECTED_TOKEN, ScannerErrorCode.EXPECTED_TOKEN],
              "do {} while (a);"),
          new TestDescriptor('rightParen', 'do {} while (a)',
              [ParserErrorCode.EXPECTED_TOKEN], "do {} while (a);"),
        ],
        PartialCodeTest.statementSuffixes,
        head: 'f() { ',
        tail: ' }');
  }
}
