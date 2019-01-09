// Copyright (c) 2017, the Dart project authors  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';

import 'partial_code_support.dart';

main() {
  new MethodTest().buildAll();
}

class MethodTest extends PartialCodeTest {
  buildAll() {
    const allExceptEof = const [
      'annotation',
      'field',
      'fieldConst',
      'fieldFinal',
      'methodNonVoid',
      'methodVoid',
      'getter',
      'setter'
    ];
    buildTests(
      'method_declaration',
      [
        //
        // Instance method, no return type.
        //
        new TestDescriptor(
          'noType_leftParen',
          'm(',
          [
            ScannerErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'm() {}',
          failing: allExceptEof,
        ),
        new TestDescriptor(
          'noType_paramName',
          'm(B',
          [
            ScannerErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'm(B) {}',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        new TestDescriptor(
            'noType_paramTypeAndName',
            'm(B b',
            [
              ScannerErrorCode.EXPECTED_TOKEN,
              ParserErrorCode.MISSING_FUNCTION_BODY
            ],
            'm(B b) {}'),
        new TestDescriptor(
          'noType_paramAndComma',
          'm(B b,',
          [
            ScannerErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'm(B b) {}',
          failing: allExceptEof,
        ),
        new TestDescriptor(
          'noType_noParams',
          'm()',
          [ParserErrorCode.MISSING_FUNCTION_BODY],
          'm() {}',
        ),
        new TestDescriptor(
          'noType_params',
          'm(b, c)',
          [ParserErrorCode.MISSING_FUNCTION_BODY],
          'm(b, c) {}',
        ),
        new TestDescriptor(
          'noType_emptyOptional',
          'm(B b, [])',
          [
            ParserErrorCode.MISSING_IDENTIFIER,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'm(B b, [_s_]){}',
        ),
        new TestDescriptor(
          'noType_emptyNamed',
          'm(B b, {})',
          [
            ParserErrorCode.MISSING_IDENTIFIER,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'm(B b, {_s_}){}',
        ),
        //
        // Instance method, with simple return type.
        //
        new TestDescriptor(
          'type_leftParen',
          'A m(',
          [
            ScannerErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'A m() {}',
          failing: allExceptEof,
        ),
        new TestDescriptor(
          'type_paramName',
          'A m(B',
          [
            ScannerErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'A m(B) {}',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        new TestDescriptor(
          'type_paramTypeAndName',
          'A m(B b',
          [
            ScannerErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'A m(B b) {}',
        ),
        new TestDescriptor(
          'type_paramAndComma',
          'A m(B b,',
          [
            ScannerErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'A m(B b) {}',
          failing: allExceptEof,
        ),
        new TestDescriptor(
          'type_noParams',
          'A m()',
          [ParserErrorCode.MISSING_FUNCTION_BODY],
          'A m() {}',
        ),
        new TestDescriptor(
          'type_params',
          'A m(b, c)',
          [ParserErrorCode.MISSING_FUNCTION_BODY],
          'A m(b, c) {}',
        ),
        new TestDescriptor(
          'type_emptyOptional',
          'A m(B b, [])',
          [
            ParserErrorCode.MISSING_IDENTIFIER,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'A m(B b, [_s_]){}',
        ),
        new TestDescriptor(
          'type_emptyNamed',
          'A m(B b, {})',
          [
            ParserErrorCode.MISSING_IDENTIFIER,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'A m(B b, {_s_}){}',
        ),
        //
        // Static method, no return type.
        //
        new TestDescriptor(
          'static_noType_leftParen',
          'static m(',
          [
            ScannerErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'static m() {}',
          failing: allExceptEof,
        ),
        new TestDescriptor(
          'static_noType_paramName',
          'static m(B',
          [
            ScannerErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'static m(B) {}',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        new TestDescriptor(
          'static_noType_paramTypeAndName',
          'static m(B b',
          [
            ScannerErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'static m(B b) {}',
        ),
        new TestDescriptor(
          'static_noType_paramAndComma',
          'static m(B b,',
          [
            ScannerErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'static m(B b) {}',
          failing: allExceptEof,
        ),
        new TestDescriptor(
          'static_noType_noParams',
          'static m()',
          [ParserErrorCode.MISSING_FUNCTION_BODY],
          'static m() {}',
        ),
        new TestDescriptor(
          'static_noType_params',
          'static m(b, c)',
          [ParserErrorCode.MISSING_FUNCTION_BODY],
          'static m(b, c) {}',
        ),
        new TestDescriptor(
          'static_noType_emptyOptional',
          'static m(B b, [])',
          [
            ParserErrorCode.MISSING_IDENTIFIER,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'static m(B b, [_s_]){}',
        ),
        new TestDescriptor(
          'static_noType_emptyNamed',
          'static m(B b, {})',
          [
            ParserErrorCode.MISSING_IDENTIFIER,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'static m(B b, {_s_}){}',
        ),
        //
        // Static method, with simple return type.
        //
        new TestDescriptor(
          'static_type_leftParen',
          'static A m(',
          [
            ScannerErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'static A m() {}',
          failing: allExceptEof,
        ),
        new TestDescriptor(
          'static_type_paramName',
          'static A m(B',
          [
            ScannerErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'static A m(B) {}',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        new TestDescriptor(
          'static_type_paramTypeAndName',
          'static A m(B b',
          [
            ScannerErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'static A m(B b) {}',
        ),
        new TestDescriptor(
          'static_type_paramAndComma',
          'static A m(B b,',
          [
            ScannerErrorCode.EXPECTED_TOKEN,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'static A m(B b) {}',
          failing: allExceptEof,
        ),
        new TestDescriptor(
          'static_type_noParams',
          'static A m()',
          [ParserErrorCode.MISSING_FUNCTION_BODY],
          'static A m() {}',
        ),
        new TestDescriptor(
          'static_type_params',
          'static A m(b, c)',
          [ParserErrorCode.MISSING_FUNCTION_BODY],
          'static A m(b, c) {}',
        ),
        new TestDescriptor(
          'static_type_emptyOptional',
          'static A m(B b, [])',
          [
            ParserErrorCode.MISSING_IDENTIFIER,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'static A m(B b, [_s_]){}',
        ),
        new TestDescriptor(
          'static_type_emptyNamed',
          'static A m(B b, {})',
          [
            ParserErrorCode.MISSING_IDENTIFIER,
            ParserErrorCode.MISSING_FUNCTION_BODY
          ],
          'static A m(B b, {_s_}){}',
        ),
      ],
      PartialCodeTest.classMemberSuffixes,
      head: 'class C { ',
      tail: ' }',
    );
  }
}
