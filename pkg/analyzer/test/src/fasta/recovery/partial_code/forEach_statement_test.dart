// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new ForEachStatementTest().buildAll();
}

class ForEachStatementTest extends PartialCodeTest {
  buildAll() {
    //
    // Without a preceding 'await', anything that doesn't contain the `in`
    // keyword will be interpreted as a normal for statement.
    //
    buildTests(
        'forEach_statement',
        [
          new TestDescriptor(
              'in',
              'for (var a in',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ScannerErrorCode.EXPECTED_TOKEN
              ],
              'for (var a in _s_) {}',
              allFailing: true),
          new TestDescriptor(
              'iterator',
              'for (var a in b',
              [ParserErrorCode.EXPECTED_TOKEN, ScannerErrorCode.EXPECTED_TOKEN],
              'for (var a in b) {}',
              allFailing: true),
        ],
        PartialCodeTest.statementSuffixes,
        head: 'f() { ',
        tail: ' }');
    //
    // With a preceding 'await', everything should be interpreted as a
    // for-each statement.
    //
    buildTests(
        'forEach_statement',
        [
          new TestDescriptor(
              'await_keyword',
              'await for',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ScannerErrorCode.EXPECTED_TOKEN
              ],
              'await for (_s_ in _s_) {}',
              allFailing: true),
          new TestDescriptor(
              'await_leftParen',
              'await for (',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ScannerErrorCode.EXPECTED_TOKEN
              ],
              "await for (_s_ in _s_) {}",
              allFailing: true),
          new TestDescriptor(
              'await_variableName',
              'await for (a',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ScannerErrorCode.EXPECTED_TOKEN
              ],
              "await for (a in _s_) {}",
              allFailing: true),
          new TestDescriptor(
              'await_typeAndVariableName',
              'await for (A a',
              [
                ParserErrorCode.EXPECTED_TOKEN,
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ScannerErrorCode.EXPECTED_TOKEN
              ],
              "await for (a in _s_) {}",
              allFailing: true),
          new TestDescriptor(
              'await_in',
              'await for (A a in',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN,
                ScannerErrorCode.EXPECTED_TOKEN
              ],
              "await for (a in _s_) {}",
              allFailing: true),
          new TestDescriptor(
              'await_stream',
              'await for (A a in b',
              [ParserErrorCode.EXPECTED_TOKEN, ScannerErrorCode.EXPECTED_TOKEN],
              "await for (a in b) {}",
              allFailing: true),
        ],
        PartialCodeTest.statementSuffixes,
        head: 'f() async { ',
        tail: ' }');
  }
}
