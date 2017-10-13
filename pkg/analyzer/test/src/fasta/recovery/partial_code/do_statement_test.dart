// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new DoStatementTest().buildAll();
}

class DoStatementTest extends PartialCodeTest {
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
              'rightBrace',
              'do {}',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "do {} while (_s_);",
              allFailing: true),
          new TestDescriptor(
              'while',
              'do {} while',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "do {} while (_s_);",
              allFailing: true),
          new TestDescriptor(
              'leftParen',
              'do {} while (',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "do {} while (_s_);",
              allFailing: true),
          new TestDescriptor(
              'condition',
              'do {} while (a',
              [ParserErrorCode.EXPECTED_TOKEN, ParserErrorCode.EXPECTED_TOKEN],
              "do {} while (a);",
              allFailing: true),
          new TestDescriptor('rightParen', 'do {} while (a)',
              [ParserErrorCode.EXPECTED_TOKEN], "do {} while (a);"),
        ],
        PartialCodeTest.statementSuffixes,
        head: 'f() { ',
        tail: ' }');
  }
}
