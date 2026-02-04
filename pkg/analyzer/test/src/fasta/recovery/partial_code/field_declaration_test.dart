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
    List<String> allExceptAnnotationAndEof = <String>[
      'field',
      'fieldConst',
      'fieldFinal',
      'methodNonVoid',
      'methodVoid',
      'getter',
      'setter',
    ];
    buildTests(
      'field_declaration',
      [
        //
        // Instance field, const.
        //
        TestDescriptor(
          'const_noName',
          'const',
          [diag.missingIdentifier, diag.expectedToken],
          'const _s_;',
          failing: allExceptAnnotationAndEof,
          expectedDiagnosticsInValidCode: [diag.constNotInitialized],
        ),
        TestDescriptor(
          'const_name',
          'const f',
          [diag.expectedToken, diag.constNotInitialized],
          'const f;',
          failing: ['methodNonVoid', 'getter', 'setter'],
          expectedDiagnosticsInValidCode: [diag.constNotInitialized],
        ),
        TestDescriptor(
          'const_equals',
          'const f =',
          [diag.missingIdentifier, diag.expectedToken],
          'const f = _s_;',
          failing: [
            'fieldConst',
            'methodNonVoid',
            'methodVoid',
            'getter',
            'setter',
          ],
        ),
        TestDescriptor('const_initializer', 'const f = 0', [
          diag.expectedToken,
        ], 'const f = 0;'),
        //
        // Instance field, final.
        //
        TestDescriptor(
          'final_noName',
          'final',
          [diag.missingIdentifier, diag.expectedToken],
          'final _s_;',
          failing: allExceptAnnotationAndEof,
        ),
        TestDescriptor(
          'final_name',
          'final f',
          [diag.expectedToken],
          'final f;',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'final_equals',
          'final f =',
          [diag.missingIdentifier, diag.expectedToken],
          'final f = _s_;',
          failing: [
            'fieldConst',
            'methodNonVoid',
            'methodVoid',
            'getter',
            'setter',
          ],
        ),
        TestDescriptor('final_initializer', 'final f = 0', [
          diag.expectedToken,
        ], 'final f = 0;'),
        //
        // Instance field, var.
        //
        TestDescriptor(
          'var_noName',
          'var',
          [diag.missingIdentifier, diag.expectedToken],
          'var _s_;',
          failing: allExceptAnnotationAndEof,
        ),
        TestDescriptor(
          'var_name',
          'var f',
          [diag.expectedToken],
          'var f;',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'var_name_comma',
          'var f,',
          [diag.missingIdentifier, diag.expectedToken],
          'var f, _s_;',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'var_equals',
          'var f =',
          [diag.missingIdentifier, diag.expectedToken],
          'var f = _s_;',
          failing: [
            'fieldConst',
            'methodNonVoid',
            'methodVoid',
            'getter',
            'setter',
          ],
        ),
        TestDescriptor('var_initializer', 'var f = 0', [
          diag.expectedToken,
        ], 'var f = 0;'),
        //
        // Instance field, type.
        //
        TestDescriptor(
          'type_noName',
          'A',
          [diag.missingConstFinalVarOrType, diag.expectedToken],
          'A _s_;',
          allFailing: true,
        ),
        TestDescriptor('type_name', 'A f', [diag.expectedToken], 'A f;'),
        TestDescriptor(
          'type_name_comma',
          'A f,',
          [diag.missingIdentifier, diag.expectedToken],
          'A f, _s_;',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'type_equals',
          'A f =',
          [diag.missingIdentifier, diag.expectedToken],
          'A f = _s_;',
          failing: [
            'fieldConst',
            'methodNonVoid',
            'methodVoid',
            'getter',
            'setter',
          ],
        ),
        TestDescriptor('type_initializer', 'A f = 0', [
          diag.expectedToken,
        ], 'A f = 0;'),
        //
        // Static field, const.
        //
        TestDescriptor(
          'static_const_noName',
          'static const',
          [diag.missingIdentifier, diag.expectedToken],
          'static const _s_;',
          failing: allExceptAnnotationAndEof,
          expectedDiagnosticsInValidCode: [diag.constNotInitialized],
        ),
        TestDescriptor(
          'static_const_name',
          'static const f',
          [diag.expectedToken, diag.constNotInitialized],
          'static const f;',
          failing: ['methodNonVoid', 'getter', 'setter'],
          expectedDiagnosticsInValidCode: [diag.constNotInitialized],
        ),
        TestDescriptor(
          'static_const_equals',
          'static const f =',
          [diag.missingIdentifier, diag.expectedToken],
          'static const f = _s_;',
          failing: [
            'fieldConst',
            'methodNonVoid',
            'methodVoid',
            'getter',
            'setter',
          ],
        ),
        TestDescriptor('static_const_initializer', 'static const f = 0', [
          diag.expectedToken,
        ], 'static const f = 0;'),
        //
        // Static field, final.
        //
        TestDescriptor(
          'static_final_noName',
          'static final',
          [diag.missingIdentifier, diag.expectedToken],
          'static final _s_;',
          failing: allExceptAnnotationAndEof,
        ),
        TestDescriptor(
          'static_final_name',
          'static final f',
          [diag.expectedToken],
          'static final f;',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'static_final_equals',
          'static final f =',
          [diag.missingIdentifier, diag.expectedToken],
          'static final f = _s_;',
          failing: [
            'fieldConst',
            'methodNonVoid',
            'methodVoid',
            'getter',
            'setter',
          ],
        ),
        TestDescriptor('static_final_initializer', 'static final f = 0', [
          diag.expectedToken,
        ], 'static final f = 0;'),
        //
        // Static field, var.
        //
        TestDescriptor(
          'static_var_noName',
          'static var',
          [diag.missingIdentifier, diag.expectedToken],
          'static var _s_;',
          failing: allExceptAnnotationAndEof,
        ),
        TestDescriptor(
          'static_var_name',
          'static var f',
          [diag.expectedToken],
          'static var f;',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'static_var_equals',
          'static var f =',
          [diag.missingIdentifier, diag.expectedToken],
          'static var f = _s_;',
          failing: [
            'fieldConst',
            'methodNonVoid',
            'methodVoid',
            'getter',
            'setter',
          ],
        ),
        TestDescriptor('static_var_initializer', 'static var f = 0', [
          diag.expectedToken,
        ], 'static var f = 0;'),
        //
        // Static field, type.
        //
        TestDescriptor(
          'static_type_noName',
          'static A',
          [diag.missingConstFinalVarOrType, diag.expectedToken],
          'static A _s_;',
          allFailing: true,
        ),
        TestDescriptor('static_type_name', 'static A f', [
          diag.expectedToken,
        ], 'static A f;'),
        TestDescriptor(
          'static_type_equals',
          'static A f =',
          [diag.missingIdentifier, diag.expectedToken],
          'static A f = _s_;',
          failing: [
            'fieldConst',
            'methodNonVoid',
            'methodVoid',
            'getter',
            'setter',
          ],
        ),
        TestDescriptor('static_type_initializer', 'static A f = 0', [
          diag.expectedToken,
        ], 'static A f = 0;'),
      ],
      PartialCodeTest.classMemberSuffixes,
      head: 'class C { ',
      tail: ' }',
    );
  }
}
