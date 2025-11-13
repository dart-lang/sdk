// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;

import 'partial_code_support.dart';

main() {
  LocalVariableTest().buildAll();
}

class LocalVariableTest extends PartialCodeTest {
  buildAll() {
    buildTests(
      'local_variable',
      [
        TestDescriptor(
          'const',
          'const',
          [diag.missingIdentifier, diag.expectedToken],
          "const _s_;",
          allFailing: true,
        ),
        TestDescriptor(
          'constName',
          'const a',
          [diag.expectedToken],
          "const a;",
          failing: <String>['eof', 'labeled', 'localFunctionNonVoid'],
        ),
        TestDescriptor('constTypeName', 'const int a', [
          diag.expectedToken,
        ], "const int a;"),
        TestDescriptor(
          'constNameComma',
          'const a,',
          [diag.missingIdentifier, diag.expectedToken],
          "const a, _s_;",
          failing: <String>['labeled', 'localFunctionNonVoid'],
        ),
        TestDescriptor(
          'constTypeNameComma',
          'const int a,',
          [diag.missingIdentifier, diag.expectedToken],
          "const int a, _s_;",
          failing: ['labeled', 'localFunctionNonVoid'],
        ),
        TestDescriptor('constNameCommaName', 'const a, b', [
          diag.expectedToken,
        ], "const a, b;"),
        TestDescriptor('constTypeNameCommaName', 'const int a, b', [
          diag.expectedToken,
        ], "const int a, b;"),
        TestDescriptor(
          'final',
          'final',
          [diag.missingIdentifier, diag.expectedToken],
          "final _s_;",
          failing: [
            'labeled',
            'localFunctionNonVoid',
            'localFunctionVoid',
            'localVariable',
          ],
        ),
        TestDescriptor(
          'finalName',
          'final a',
          [diag.expectedToken],
          "final a;",
          failing: ['labeled', 'localFunctionNonVoid'],
        ),
        TestDescriptor('finalTypeName', 'final int a', [
          diag.expectedToken,
        ], "final int a;"),
        TestDescriptor(
          'type',
          'int',
          [diag.missingIdentifier, diag.expectedToken],
          "int _s_;",
          allFailing: true,
        ),
        TestDescriptor('typeName', 'int a', [diag.expectedToken], "int a;"),
        TestDescriptor(
          'var',
          'var',
          [diag.missingIdentifier, diag.expectedToken],
          "var _s_;",
          failing: [
            'labeled',
            'localFunctionNonVoid',
            'localFunctionVoid',
            'localVariable',
          ],
        ),
        TestDescriptor(
          'varName',
          'var a',
          [diag.expectedToken],
          "var a;",
          failing: ['labeled', 'localFunctionNonVoid'],
        ),
        TestDescriptor(
          'varNameEquals',
          'var a =',
          [diag.missingIdentifier, diag.expectedToken],
          "var a = _s_;",
          failing: [
            'block',
            'assert',
            'labeled',
            'localFunctionNonVoid',
            'localFunctionVoid',
            'return',
            'switch',
          ],
        ),
        TestDescriptor('varNameEqualsExpression', 'var a = b', [
          diag.expectedToken,
        ], "var a = b;"),
      ],
      PartialCodeTest.statementSuffixes,
      head: 'f() { ',
      tail: ' }',
    );
  }
}
