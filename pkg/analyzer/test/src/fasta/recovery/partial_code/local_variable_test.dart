// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

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
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
          "const _s_;",
          allFailing: true,
        ),
        TestDescriptor(
          'constName',
          'const a',
          [ParserErrorCode.expectedToken],
          "const a;",
          failing: <String>['eof', 'labeled', 'localFunctionNonVoid'],
        ),
        TestDescriptor('constTypeName', 'const int a', [
          ParserErrorCode.expectedToken,
        ], "const int a;"),
        TestDescriptor(
          'constNameComma',
          'const a,',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
          "const a, _s_;",
          failing: <String>['labeled', 'localFunctionNonVoid'],
        ),
        TestDescriptor(
          'constTypeNameComma',
          'const int a,',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
          "const int a, _s_;",
          failing: ['labeled', 'localFunctionNonVoid'],
        ),
        TestDescriptor('constNameCommaName', 'const a, b', [
          ParserErrorCode.expectedToken,
        ], "const a, b;"),
        TestDescriptor('constTypeNameCommaName', 'const int a, b', [
          ParserErrorCode.expectedToken,
        ], "const int a, b;"),
        TestDescriptor(
          'final',
          'final',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
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
          [ParserErrorCode.expectedToken],
          "final a;",
          failing: ['labeled', 'localFunctionNonVoid'],
        ),
        TestDescriptor('finalTypeName', 'final int a', [
          ParserErrorCode.expectedToken,
        ], "final int a;"),
        TestDescriptor(
          'type',
          'int',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
          "int _s_;",
          allFailing: true,
        ),
        TestDescriptor('typeName', 'int a', [
          ParserErrorCode.expectedToken,
        ], "int a;"),
        TestDescriptor(
          'var',
          'var',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
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
          [ParserErrorCode.expectedToken],
          "var a;",
          failing: ['labeled', 'localFunctionNonVoid'],
        ),
        TestDescriptor(
          'varNameEquals',
          'var a =',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
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
          ParserErrorCode.expectedToken,
        ], "var a = b;"),
      ],
      PartialCodeTest.statementSuffixes,
      head: 'f() { ',
      tail: ' }',
    );
  }
}
