// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new YieldStatementTest().buildAll();
}

class YieldStatementTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'yield_statement',
        [
          new TestDescriptor(
              'keyword',
              'yield',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "yield _s_;",
              failing: [
                'assert',
                'block',
                'labeled',
                'localFunctionNonVoid',
                'localFunctionVoid',
                'return',
              ]),
          new TestDescriptor('expression', 'yield a',
              [ParserErrorCode.EXPECTED_TOKEN], "yield a;"),
          new TestDescriptor(
              'star',
              'yield *',
              [
                ParserErrorCode.MISSING_IDENTIFIER,
                ParserErrorCode.EXPECTED_TOKEN
              ],
              "yield * _s_;",
              failing: [
                'assert',
                'block',
                'labeled',
                'localFunctionNonVoid',
                'localFunctionVoid',
                'return',
              ]),
          new TestDescriptor('star_expression', 'yield * a',
              [ParserErrorCode.EXPECTED_TOKEN], "yield * a;"),
        ],
        PartialCodeTest.statementSuffixes,
        head: 'f() sync* { ',
        tail: ' }');
  }
}
