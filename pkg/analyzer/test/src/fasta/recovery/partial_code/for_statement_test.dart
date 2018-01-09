// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new ForStatementTest().buildAll();
}

class ForStatementTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'for_statement',
        [
          new TestDescriptor(
              'keyword',
              'for',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              'for (;;) {}',
              allFailing: true),
          new TestDescriptor(
              'leftParen',
              'for (',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "for (;;) {}",
              allFailing: true),
          new TestDescriptor(
              'var',
              'for (var',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "for (var _s_;;) {}",
              allFailing: true),
          new TestDescriptor(
              'varAndIdentifier',
              'for (var i',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "for (var i;;) {}",
              allFailing: true),
          new TestDescriptor(
              'equals',
              'for (var i =',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "for (var i = _s_;;) {}",
              allFailing: true),
          new TestDescriptor(
              'initializer',
              'for (var i = 0',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "for (var i = 0;;) {}",
              allFailing: true),
          new TestDescriptor(
              'firstSemicolon',
              'for (var i = 0;',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "for (var i = 0;;) {}",
              allFailing: true),
          new TestDescriptor(
              'secondSemicolon',
              'for (var i = 0;;',
              [ParserErrorCode.EXPECTED_TOKEN, ParserErrorCode.EXPECTED_TOKEN],
              "for (var i = 0;;) {}",
              allFailing: true),
          new TestDescriptor('rightParen', 'for (var i = 0;;)',
              [ParserErrorCode.EXPECTED_TOKEN], "for (var i = 0;;) {}",
              allFailing: true),
        ],
        PartialCodeTest.statementSuffixes,
        head: 'f() { ',
        tail: ' }');
  }
}
