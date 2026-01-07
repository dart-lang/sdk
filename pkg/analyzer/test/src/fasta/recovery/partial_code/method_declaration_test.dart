// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;

import 'partial_code_support.dart';

main() {
  MethodTest().buildAll();
}

class MethodTest extends PartialCodeTest {
  buildAll() {
    const allExceptEof = [
      'annotation',
      'field',
      'fieldConst',
      'fieldFinal',
      'methodNonVoid',
      'methodVoid',
      'getter',
      'setter',
    ];
    buildTests(
      'method_declaration',
      [
        //
        // Instance method, no return type.
        //
        TestDescriptor(
          'noType_leftParen',
          'm(',
          [diag.expectedToken, diag.missingFunctionBody],
          'm() {}',
          failing: allExceptEof,
        ),
        TestDescriptor(
          'noType_paramName',
          'm(B',
          [diag.expectedToken, diag.missingFunctionBody],
          'm(B) {}',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor('noType_paramTypeAndName', 'm(B b', [
          diag.expectedToken,
          diag.missingFunctionBody,
        ], 'm(B b) {}'),
        TestDescriptor(
          'noType_paramAndComma',
          'm(B b,',
          [diag.expectedToken, diag.missingFunctionBody],
          'm(B b) {}',
          failing: allExceptEof,
        ),
        TestDescriptor('noType_noParams', 'm()', [
          diag.missingFunctionBody,
        ], 'm() {}'),
        TestDescriptor('noType_params', 'm(b, c)', [
          diag.missingFunctionBody,
        ], 'm(b, c) {}'),
        TestDescriptor('noType_emptyOptional', 'm(B b, [])', [
          diag.missingIdentifier,
          diag.missingFunctionBody,
        ], 'm(B b, [_s_]){}'),
        TestDescriptor('noType_emptyNamed', 'm(B b, {})', [
          diag.missingIdentifier,
          diag.missingFunctionBody,
        ], 'm(B b, {_s_}){}'),
        //
        // Instance method, with simple return type.
        //
        TestDescriptor(
          'type_leftParen',
          'A m(',
          [diag.expectedToken, diag.missingFunctionBody],
          'A m() {}',
          failing: allExceptEof,
        ),
        TestDescriptor(
          'type_paramName',
          'A m(B',
          [diag.expectedToken, diag.missingFunctionBody],
          'A m(B) {}',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor('type_paramTypeAndName', 'A m(B b', [
          diag.expectedToken,
          diag.missingFunctionBody,
        ], 'A m(B b) {}'),
        TestDescriptor(
          'type_paramAndComma',
          'A m(B b,',
          [diag.expectedToken, diag.missingFunctionBody],
          'A m(B b) {}',
          failing: allExceptEof,
        ),
        TestDescriptor('type_noParams', 'A m()', [
          diag.missingFunctionBody,
        ], 'A m() {}'),
        TestDescriptor('type_params', 'A m(b, c)', [
          diag.missingFunctionBody,
        ], 'A m(b, c) {}'),
        TestDescriptor('type_emptyOptional', 'A m(B b, [])', [
          diag.missingIdentifier,
          diag.missingFunctionBody,
        ], 'A m(B b, [_s_]){}'),
        TestDescriptor('type_emptyNamed', 'A m(B b, {})', [
          diag.missingIdentifier,
          diag.missingFunctionBody,
        ], 'A m(B b, {_s_}){}'),
        //
        // Static method, no return type.
        //
        TestDescriptor(
          'static_noType_leftParen',
          'static m(',
          [diag.expectedToken, diag.missingFunctionBody],
          'static m() {}',
          failing: allExceptEof,
        ),
        TestDescriptor(
          'static_noType_paramName',
          'static m(B',
          [diag.expectedToken, diag.missingFunctionBody],
          'static m(B) {}',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor('static_noType_paramTypeAndName', 'static m(B b', [
          diag.expectedToken,
          diag.missingFunctionBody,
        ], 'static m(B b) {}'),
        TestDescriptor(
          'static_noType_paramAndComma',
          'static m(B b,',
          [diag.expectedToken, diag.missingFunctionBody],
          'static m(B b) {}',
          failing: allExceptEof,
        ),
        TestDescriptor('static_noType_noParams', 'static m()', [
          diag.missingFunctionBody,
        ], 'static m() {}'),
        TestDescriptor('static_noType_params', 'static m(b, c)', [
          diag.missingFunctionBody,
        ], 'static m(b, c) {}'),
        TestDescriptor(
          'static_noType_emptyOptional',
          'static m(B b, [])',
          [diag.missingIdentifier, diag.missingFunctionBody],
          'static m(B b, [_s_]){}',
        ),
        TestDescriptor('static_noType_emptyNamed', 'static m(B b, {})', [
          diag.missingIdentifier,
          diag.missingFunctionBody,
        ], 'static m(B b, {_s_}){}'),
        //
        // Static method, with simple return type.
        //
        TestDescriptor(
          'static_type_leftParen',
          'static A m(',
          [diag.expectedToken, diag.missingFunctionBody],
          'static A m() {}',
          failing: allExceptEof,
        ),
        TestDescriptor(
          'static_type_paramName',
          'static A m(B',
          [diag.expectedToken, diag.missingFunctionBody],
          'static A m(B) {}',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor('static_type_paramTypeAndName', 'static A m(B b', [
          diag.expectedToken,
          diag.missingFunctionBody,
        ], 'static A m(B b) {}'),
        TestDescriptor(
          'static_type_paramAndComma',
          'static A m(B b,',
          [diag.expectedToken, diag.missingFunctionBody],
          'static A m(B b) {}',
          failing: allExceptEof,
        ),
        TestDescriptor('static_type_noParams', 'static A m()', [
          diag.missingFunctionBody,
        ], 'static A m() {}'),
        TestDescriptor('static_type_params', 'static A m(b, c)', [
          diag.missingFunctionBody,
        ], 'static A m(b, c) {}'),
        TestDescriptor(
          'static_type_emptyOptional',
          'static A m(B b, [])',
          [diag.missingIdentifier, diag.missingFunctionBody],
          'static A m(B b, [_s_]){}',
        ),
        TestDescriptor(
          'static_type_emptyNamed',
          'static A m(B b, {})',
          [diag.missingIdentifier, diag.missingFunctionBody],
          'static A m(B b, {_s_}){}',
        ),
      ],
      PartialCodeTest.classMemberSuffixes,
      head: 'class C { ',
      tail: ' }',
    );
  }
}
