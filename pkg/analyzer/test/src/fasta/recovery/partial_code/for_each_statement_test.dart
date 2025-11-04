// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  ForEachStatementTest().buildAll();
}

class ForEachStatementTest extends PartialCodeTest {
  buildAll() {
    List<String> allExceptEof = PartialCodeTest.statementSuffixes
        .map((t) => t.name)
        .toList();
    //
    // Without a preceding 'await', anything that doesn't contain the `in`
    // keyword will be interpreted as a normal for statement.
    //
    buildTests(
      'forEach_statement',
      [
        TestDescriptor(
          'in',
          'for (var a in',
          [
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
          'for (var a in _s_) _s_;',
          failing: allExceptEof,
        ),
        TestDescriptor(
          'iterator',
          'for (var a in b',
          [
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
          'for (var a in b) _s_;',
          failing: allExceptEof,
        ),
      ],
      PartialCodeTest.statementSuffixes,
      head: 'f() { ',
      tail: ' }',
    );
    //
    // With a preceding 'await', everything should be interpreted as a
    // for-each statement.
    //
    buildTests(
      'forEach_statement',
      [
        TestDescriptor('await_keyword', 'await for', [
          ParserErrorCode.expectedToken,
        ], 'await for (_s_ in _s_) _s_;'),
        TestDescriptor(
          'await_leftParen',
          'await for (',
          [
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.missingIdentifier,
            // TODO(danrubel): investigate why 4 missing identifier errors
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
            ParserErrorCode.expectedToken,
          ],
          "await for (_s_ in _s_) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'await_variableName',
          'await for (a',
          [
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
            ParserErrorCode.expectedToken,
          ],
          "await for (a in _s_) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'await_typeAndVariableName',
          'await for (A a',
          [
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
            ParserErrorCode.expectedToken,
          ],
          "await for (A a in _s_) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'await_in',
          'await for (A a in',
          [
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
          "await for (A a in _s_) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'await_stream',
          'await for (A a in b',
          [
            ParserErrorCode.expectedToken,
            ParserErrorCode.missingIdentifier,
            ParserErrorCode.expectedToken,
          ],
          "await for (A a in b) _s_;",
          failing: allExceptEof,
        ),
      ],
      PartialCodeTest.statementSuffixes,
      head: 'f() async { ',
      tail: ' }',
    );
  }
}
