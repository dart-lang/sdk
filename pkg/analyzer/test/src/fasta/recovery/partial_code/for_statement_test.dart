// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;

import 'partial_code_support.dart';

main() {
  ForStatementTest().buildAll();
}

class ForStatementTest extends PartialCodeTest {
  buildAll() {
    List<String> allExceptEof = PartialCodeTest.statementSuffixes
        .map((t) => t.name)
        .toList();
    buildTests(
      'for_statement',
      [
        TestDescriptor('keyword', 'for', [diag.expectedToken], 'for (;;) _s_;'),
        TestDescriptor(
          'emptyParen',
          'for ()',
          [
            diag.missingIdentifier,
            diag.expectedToken,
            diag.missingIdentifier,
            diag.expectedToken,
            diag.missingIdentifier,
            diag.expectedToken,
          ],
          "for (_s_;_s_;) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'leftParen',
          'for (',
          [
            diag.missingIdentifier,
            diag.expectedToken,
            diag.missingIdentifier,
            diag.expectedToken,
            diag.expectedToken,
            diag.missingIdentifier,
            diag.expectedToken,
          ],
          "for (_s_;_s_;) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'var',
          'for (var',
          [
            diag.missingIdentifier,
            diag.expectedToken,
            diag.expectedToken,
            diag.expectedToken,
            diag.expectedToken,
          ],
          "for (var _s_;;) _s_;",
          allFailing: true,
        ),
        TestDescriptor(
          'varAndIdentifier',
          'for (var i',
          [
            diag.expectedToken,
            diag.missingIdentifier,
            diag.expectedToken,
            diag.expectedToken,
            diag.missingIdentifier,
            diag.expectedToken,
          ],
          "for (var i;_s_;) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'equals',
          'for (var i =',
          [
            diag.missingIdentifier,
            diag.expectedToken,
            diag.missingIdentifier,
            diag.expectedToken,
            diag.expectedToken,
            diag.missingIdentifier,
            diag.expectedToken,
          ],
          "for (var i = _s_;_s_;) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'initializer',
          'for (var i = 0',
          [
            diag.expectedToken,
            diag.missingIdentifier,
            diag.expectedToken,
            diag.expectedToken,
            diag.missingIdentifier,
            diag.expectedToken,
          ],
          "for (var i = 0;_s_;) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'firstSemicolon',
          'for (var i = 0;',
          [
            diag.missingIdentifier,
            diag.expectedToken,
            diag.expectedToken,
            diag.missingIdentifier,
            diag.expectedToken,
          ],
          "for (var i = 0;_s_;) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'secondSemicolon',
          'for (var i = 0;;',
          [diag.expectedToken, diag.missingIdentifier, diag.expectedToken],
          "for (var i = 0;;) _s_;",
          failing: allExceptEof,
        ),
        TestDescriptor(
          'rightParen',
          'for (var i = 0;;)',
          [diag.missingIdentifier, diag.expectedToken],
          "for (var i = 0;;) _s_;",
          failing: allExceptEof,
        ),
      ],
      PartialCodeTest.statementSuffixes,
      head: 'f() { ',
      tail: ' }',
    );
  }
}
