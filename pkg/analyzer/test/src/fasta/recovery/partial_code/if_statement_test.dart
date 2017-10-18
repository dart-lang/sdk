// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new IfStatementTest().buildAll();
}

class IfStatementTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'if_statement',
        [
          new TestDescriptor(
              'keyword',
              'if',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "if (_s_)",
              failing: ['eof']),
          new TestDescriptor(
              'leftParen',
              'if (',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "if (_s_)",
              allFailing: true),
          new TestDescriptor(
              'condition', 'if (a', [ParserErrorCode.EXPECTED_TOKEN], "if (a)",
              allFailing: true),
        ],
        PartialCodeTest.statementSuffixes,
        head: 'f() { ',
        tail: ' }');
  }
}
