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
    buildTests(
        'assert_statement',
        [
          new TestDescriptor(
              'keyword',
              'assert',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "assert (_s_);",
              allFailing: true),
          new TestDescriptor(
              'leftParen',
              'assert (',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "assert (_s_);",
              allFailing: true),
          new TestDescriptor(
              'condition',
              'assert (a',
              [ParserErrorCode.EXPECTED_TOKEN, ParserErrorCode.EXPECTED_TOKEN],
              "assert (a);",
              allFailing: true),
          new TestDescriptor(
              'comma',
              'assert (a,',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "assert (a, _s_);",
              allFailing: true),
          new TestDescriptor(
              'message',
              'assert (a, b',
              [ParserErrorCode.EXPECTED_TOKEN, ParserErrorCode.EXPECTED_TOKEN],
              "assert (a, b);",
              allFailing: true),
          new TestDescriptor(
              'trailingComma',
              'assert (a, b,',
              [ParserErrorCode.EXPECTED_TOKEN, ParserErrorCode.EXPECTED_TOKEN],
              "assert (a, b,);",
              allFailing: true),
          new TestDescriptor('rightParen', 'assert (a, b)',
              [ParserErrorCode.EXPECTED_TOKEN], "assert (a, b);",
              allFailing: true),
        ],
        PartialCodeTest.statementSuffixes,
        head: 'f() { ',
        tail: ' }');
  }
}
