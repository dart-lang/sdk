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
    List<String> allExceptEof =
        PartialCodeTest.statementSuffixes.map((t) => t.name).toList();
    buildTests(
        'for_statement',
        [
          new TestDescriptor('keyword', 'for', [ParserErrorCode.EXPECTED_TOKEN],
              'for (;;) _s_;'),
          new TestDescriptor(
              'emptyParen',
              'for ()',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "for (_s_;_s_;) _s_;",
              failing: allExceptEof),
          new TestDescriptor(
              'leftParen',
              'for (',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ScannerErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "for (_s_;_s_;) _s_;",
              failing: allExceptEof),
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
              "for (var _s_;;) _s_;",
              allFailing: true),
          new TestDescriptor(
              'varAndIdentifier',
              'for (var i',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ScannerErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "for (var i;_s_;) _s_;",
              failing: allExceptEof),
          new TestDescriptor(
              'equals',
              'for (var i =',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ScannerErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "for (var i = _s_;_s_;) _s_;",
              failing: allExceptEof),
          new TestDescriptor(
              'initializer',
              'for (var i = 0',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ScannerErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "for (var i = 0;_s_;) _s_;",
              failing: allExceptEof),
          new TestDescriptor(
              'firstSemicolon',
              'for (var i = 0;',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ScannerErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "for (var i = 0;_s_;) _s_;",
              failing: allExceptEof),
          new TestDescriptor(
              'secondSemicolon',
              'for (var i = 0;;',
              [
                ScannerErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "for (var i = 0;;) _s_;",
              failing: allExceptEof),
          new TestDescriptor(
              'rightParen',
              'for (var i = 0;;)',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "for (var i = 0;;) _s_;",
              failing: allExceptEof),
        ],
        PartialCodeTest.statementSuffixes,
        head: 'f() { ',
        tail: ' }');
  }
}
