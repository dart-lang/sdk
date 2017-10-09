// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new ContinueStatementTest().buildAll();
}

class ContinueStatementTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'continue_statement',
        [
          new TestDescriptor('keyword', 'continue',
              [ParserErrorCode.EXPECTED_TOKEN], "continue;",
              allFailing: true),
          new TestDescriptor('label', 'continue a',
              [ParserErrorCode.EXPECTED_TOKEN], "continue a;",
              allFailing: true),
        ],
        PartialCodeTest.statementSuffixes,
        head: 'f() { ',
        tail: ' }');
  }
}
