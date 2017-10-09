// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new BreakStatementTest().buildAll();
}

class BreakStatementTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'break_statement',
        [
          new TestDescriptor(
              'keyword', 'break', [ParserErrorCode.EXPECTED_TOKEN], "break;",
              allFailing: true),
          new TestDescriptor(
              'label', 'break a', [ParserErrorCode.EXPECTED_TOKEN], "break a;",
              allFailing: true),
        ],
        PartialCodeTest.statementSuffixes,
        head: 'f() { ',
        tail: ' }');
  }
}
