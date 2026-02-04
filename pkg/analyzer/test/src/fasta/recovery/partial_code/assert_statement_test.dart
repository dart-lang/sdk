// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;

import 'partial_code_support.dart';

main() {
  AssertStatementTest().buildAll();
}

class AssertStatementTest extends PartialCodeTest {
  buildAll() {
    List<String> allExceptEof = PartialCodeTest.statementSuffixes
        .map((t) => t.name)
        .toList();
    buildTests(
      'assert_statement',
      [
        TestDescriptor('keyword', 'assert', [
          diag.expectedToken,
          diag.expectedToken,
        ], "assert (_s_);"),
        TestDescriptor(
          'leftParen',
          'assert (',
          [diag.missingIdentifier, diag.expectedToken, diag.expectedToken],
          "assert (_s_);",
          failing: [
            'assert',
            'block',
            'labeled',
            'localFunctionNonVoid',
            'localFunctionVoid',
            'return',
            'switch',
          ],
        ),
        TestDescriptor('condition', 'assert (a', [
          diag.expectedToken,
          diag.expectedToken,
        ], "assert (a);"),
        TestDescriptor(
          'comma',
          'assert (a,',
          [diag.expectedToken, diag.expectedToken],
          "assert (a,);",
          failing: allExceptEof,
        ),
        TestDescriptor('message', 'assert (a, b', [
          diag.expectedToken,
          diag.expectedToken,
        ], "assert (a, b);"),
        TestDescriptor('trailingComma', 'assert (a, b,', [
          diag.expectedToken,
          diag.expectedToken,
        ], "assert (a, b,);"),
        TestDescriptor('rightParen', 'assert (a, b)', [
          diag.expectedToken,
        ], "assert (a, b);"),
      ],
      PartialCodeTest.statementSuffixes,
      head: 'f() { ',
      tail: ' }',
    );
  }
}
