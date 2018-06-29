// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';

import 'partial_code_support.dart';

main() {
  new TopLevelVariableTest().buildAll();
}

class TopLevelVariableTest extends PartialCodeTest {
  buildAll() {
    buildTests(
        'top_level_variable',
        [
          new TestDescriptor(
            'const',
            'const',
            [
              ParserErrorCode.MISSING_IDENTIFIER,
              ParserErrorCode.EXPECTED_TOKEN,
            ],
            "const _s_;",
            failing: [
              'class',
              'functionVoid',
              'functionNonVoid',
              'getter',
              'setter'
            ],
            expectedErrorsInValidCode: [
              CompileTimeErrorCode.CONST_NOT_INITIALIZED
            ],
          ),
          new TestDescriptor(
            'constName',
            'const a',
            [
              ParserErrorCode.EXPECTED_TOKEN,
              CompileTimeErrorCode.CONST_NOT_INITIALIZED
            ],
            "const a;",
            failing: ['functionNonVoid', 'getter', 'setter'],
            expectedErrorsInValidCode: [
              CompileTimeErrorCode.CONST_NOT_INITIALIZED
            ],
          ),
          new TestDescriptor(
            'constTypeName',
            'const int a',
            [
              ParserErrorCode.EXPECTED_TOKEN,
              CompileTimeErrorCode.CONST_NOT_INITIALIZED
            ],
            "const int a;",
            expectedErrorsInValidCode: [
              CompileTimeErrorCode.CONST_NOT_INITIALIZED
            ],
          ),
          new TestDescriptor(
            'constNameComma',
            'const a,',
            [
              ParserErrorCode.MISSING_IDENTIFIER,
              ParserErrorCode.EXPECTED_TOKEN,
              CompileTimeErrorCode.CONST_NOT_INITIALIZED
            ],
            "const a, _s_;",
            failing: ['functionNonVoid', 'getter'],
            expectedErrorsInValidCode: [
              CompileTimeErrorCode.CONST_NOT_INITIALIZED,
              CompileTimeErrorCode.CONST_NOT_INITIALIZED
            ],
          ),
          new TestDescriptor(
            'constTypeNameComma',
            'const int a,',
            [
              ParserErrorCode.MISSING_IDENTIFIER,
              ParserErrorCode.EXPECTED_TOKEN,
              CompileTimeErrorCode.CONST_NOT_INITIALIZED
            ],
            "const int a, _s_;",
            failing: ['functionNonVoid', 'getter'],
            expectedErrorsInValidCode: [
              CompileTimeErrorCode.CONST_NOT_INITIALIZED,
              CompileTimeErrorCode.CONST_NOT_INITIALIZED
            ],
          ),
          new TestDescriptor(
            'constNameCommaName',
            'const a, b',
            [
              ParserErrorCode.EXPECTED_TOKEN,
              CompileTimeErrorCode.CONST_NOT_INITIALIZED,
              CompileTimeErrorCode.CONST_NOT_INITIALIZED
            ],
            "const a, b;",
            expectedErrorsInValidCode: [
              CompileTimeErrorCode.CONST_NOT_INITIALIZED,
              CompileTimeErrorCode.CONST_NOT_INITIALIZED
            ],
          ),
          new TestDescriptor(
            'constTypeNameCommaName',
            'const int a, b',
            [
              ParserErrorCode.EXPECTED_TOKEN,
              CompileTimeErrorCode.CONST_NOT_INITIALIZED,
              CompileTimeErrorCode.CONST_NOT_INITIALIZED
            ],
            "const int a, b;",
            expectedErrorsInValidCode: [
              CompileTimeErrorCode.CONST_NOT_INITIALIZED,
              CompileTimeErrorCode.CONST_NOT_INITIALIZED
            ],
          ),
          new TestDescriptor(
            'final',
            'final',
            [
              ParserErrorCode.MISSING_IDENTIFIER,
              ParserErrorCode.EXPECTED_TOKEN,
            ],
            "final _s_;",
            failing: [
              'class',
              'functionVoid',
              'functionNonVoid',
              'getter',
              'setter'
            ],
            expectedErrorsInValidCode: [
              StaticWarningCode.FINAL_NOT_INITIALIZED
            ],
          ),
          new TestDescriptor(
            'finalName',
            'final a',
            [
              ParserErrorCode.EXPECTED_TOKEN,
              StaticWarningCode.FINAL_NOT_INITIALIZED
            ],
            "final a;",
            failing: ['functionNonVoid', 'getter', 'setter'],
            expectedErrorsInValidCode: [
              StaticWarningCode.FINAL_NOT_INITIALIZED
            ],
          ),
          new TestDescriptor(
            'finalTypeName',
            'final int a',
            [
              ParserErrorCode.EXPECTED_TOKEN,
              StaticWarningCode.FINAL_NOT_INITIALIZED
            ],
            "final int a;",
            expectedErrorsInValidCode: [
              StaticWarningCode.FINAL_NOT_INITIALIZED
            ],
          ),
          new TestDescriptor(
            'type',
            'int',
            [
              ParserErrorCode.MISSING_CONST_FINAL_VAR_OR_TYPE,
              ParserErrorCode.EXPECTED_TOKEN
            ],
            "int _s_;",
            allFailing: true,
          ),
          new TestDescriptor(
            'typeName',
            'int a',
            [ParserErrorCode.EXPECTED_TOKEN],
            "int a;",
          ),
          new TestDescriptor(
            'var',
            'var',
            [
              ParserErrorCode.MISSING_IDENTIFIER,
              ParserErrorCode.EXPECTED_TOKEN
            ],
            "var _s_;",
            failing: ['functionVoid', 'functionNonVoid', 'getter', 'setter'],
          ),
          new TestDescriptor(
            'varName',
            'var a',
            [ParserErrorCode.EXPECTED_TOKEN],
            "var a;",
            failing: ['functionNonVoid', 'getter', 'setter'],
          ),
          new TestDescriptor(
            'varNameEquals',
            'var a =',
            [
              ParserErrorCode.MISSING_IDENTIFIER,
              ParserErrorCode.EXPECTED_TOKEN
            ],
            "var a = _s_;",
            failing: [
              'class',
              'typedef',
              'functionVoid',
              'functionNonVoid',
              'const',
              'getter',
              'setter'
            ],
          ),
          new TestDescriptor(
            'varNameEqualsExpression',
            'var a = b',
            [ParserErrorCode.EXPECTED_TOKEN],
            "var a = b;",
          ),
        ],
        PartialCodeTest.declarationSuffixes);
  }
}
