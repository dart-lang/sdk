// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new SwitchStatementTest().buildAll();
}

class SwitchStatementTest extends PartialCodeTest {
  buildAll() {
    final allExceptEof =
        PartialCodeTest.statementSuffixes.map((ts) => ts.name).toList();
    buildTests(
        'switch_statement',
        [
          new TestDescriptor(
              'keyword',
              'switch',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "switch (_s_) {}",
              failing: ['block']),
          new TestDescriptor(
              'leftParen',
              'switch (',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ScannerErrorCode.EXPECTED_TOKEN
              ],
              "switch (_s_) {}",
              failing: [
                'assert',
                'block',
                'labeled',
                'localFunctionNonVoid',
                'localFunctionVoid',
                'return'
              ]),
          new TestDescriptor(
              'expression',
              'switch (a',
              [ParserErrorCode.EXPECTED_TOKEN, ScannerErrorCode.EXPECTED_TOKEN],
              "switch (a) {}",
              failing: ['block']),
          new TestDescriptor('rightParen', 'switch (a)',
              [ParserErrorCode.EXPECTED_TOKEN], "switch (a) {}",
              failing: ['block']),
          new TestDescriptor('leftBrace', 'switch (a) {',
              [ScannerErrorCode.EXPECTED_TOKEN], "switch (a) {}",
              failing: allExceptEof),
        ],
        PartialCodeTest.statementSuffixes,
        head: 'f() { ',
        tail: ' }');
  }
}
