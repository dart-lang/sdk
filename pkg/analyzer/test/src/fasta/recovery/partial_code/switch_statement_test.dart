// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new SwitchStatementTest().buildAll();
}

class SwitchStatementTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'switch_statement',
        [
          new TestDescriptor(
              'keyword',
              'switch',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "switch (_s_) {}",
              allFailing: true),
          new TestDescriptor(
              'leftParen',
              'switch (',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "switch (_s_) {}",
              allFailing: true),
          new TestDescriptor(
              'expression',
              'switch (a',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "switch (a) {}",
              allFailing: true),
          new TestDescriptor(
              'rightParen',
              'switch (a)',
              [ParserErrorCode.EXPECTED_TOKEN, ParserErrorCode.EXPECTED_TOKEN],
              "switch (a) {}",
              allFailing: true),
          new TestDescriptor('leftBrace', 'switch (a) {',
              [ParserErrorCode.EXPECTED_TOKEN], "switch (a) {}",
              allFailing: true),
        ],
        PartialCodeTest.statementSuffixes,
        head: 'f() { ',
        tail: ' }');
  }
}
