// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;

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
            diag.missingIdentifier,
            diag.expectedToken,
            diag.missingIdentifier,
            diag.expectedToken,
          ],
          'for (var a in _s_) _s_;',
          failing: allExceptEof,
        ),
        TestDescriptor(
          'iterator',
          'for (var a in b',
          [diag.expectedToken, diag.missingIdentifier, diag.expectedToken],
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
          diag.expectedToken,
        ], 'await for (_s_ in _s_) _s_;'),
        TestDescriptor(
          'await_leftParen',
          'await for (',
          [
            diag.expectedToken,
            diag.missingIdentifier,
            diag.missingIdentifier,
            diag.missingIdentifier,
            // TODO(danrubel): investigate why 4 missing identifier errors
            diag.missingIdentifier,
            diag.expectedToken,
            diag.expectedToken,
          ],
          "await for (_s_ in _s_) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'await_variableName',
          'await for (a',
          [
            diag.expectedToken,
            diag.missingIdentifier,
            diag.missingIdentifier,
            diag.expectedToken,
            diag.expectedToken,
          ],
          "await for (a in _s_) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'await_typeAndVariableName',
          'await for (A a',
          [
            diag.expectedToken,
            diag.missingIdentifier,
            diag.missingIdentifier,
            diag.expectedToken,
            diag.expectedToken,
          ],
          "await for (A a in _s_) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'await_in',
          'await for (A a in',
          [
            diag.expectedToken,
            diag.missingIdentifier,
            diag.missingIdentifier,
            diag.expectedToken,
          ],
          "await for (A a in _s_) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'await_stream',
          'await for (A a in b',
          [diag.expectedToken, diag.missingIdentifier, diag.expectedToken],
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
