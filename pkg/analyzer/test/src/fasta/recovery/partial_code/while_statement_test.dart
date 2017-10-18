// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new WhileStatementTest().buildAll();
}

class WhileStatementTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'while_statement',
        [
          new TestDescriptor(
              'keyword',
              'while',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "while (_s_)",
              failing: ['eof']),
          new TestDescriptor(
              'leftParen',
              'while (',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "while (_s_)",
              allFailing: true),
          new TestDescriptor('condition', 'while (a',
              [ParserErrorCode.EXPECTED_TOKEN], "while (a)",
              allFailing: true),
        ],
        PartialCodeTest.statementSuffixes,
        head: 'f() { ',
        tail: ' }');
  }
}
