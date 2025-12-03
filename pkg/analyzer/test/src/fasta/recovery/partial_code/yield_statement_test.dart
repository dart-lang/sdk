// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;

import 'partial_code_support.dart';

main() {
  YieldStatementTest().buildAll();
}

class YieldStatementTest extends PartialCodeTest {
  buildAll() {
    buildTests(
      'yield_statement',
      [
        TestDescriptor(
          'keyword',
          'yield',
          [diag.missingIdentifier, diag.expectedToken],
          "yield _s_;",
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
        TestDescriptor('expression', 'yield a', [
          diag.expectedToken,
        ], "yield a;"),
        TestDescriptor(
          'star',
          'yield *',
          [diag.missingIdentifier, diag.expectedToken],
          "yield * _s_;",
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
        TestDescriptor('star_expression', 'yield * a', [
          diag.expectedToken,
        ], "yield * a;"),
      ],
      PartialCodeTest.statementSuffixes,
      head: 'f() sync* { ',
      tail: ' }',
    );
  }
}
