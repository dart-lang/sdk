// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';

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
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
          'const _s_;',
          failing: allExceptAnnotationAndEof,
          expectedDiagnosticsInValidCode: [
            CompileTimeErrorCode.constNotInitialized,
          ],
        ),
        TestDescriptor(
          'const_name',
          'const f',
          [
            ParserErrorCode.expectedToken,
            CompileTimeErrorCode.constNotInitialized,
          ],
          'const f;',
          failing: ['methodNonVoid', 'getter', 'setter'],
          expectedDiagnosticsInValidCode: [
            CompileTimeErrorCode.constNotInitialized,
          ],
        ),
        TestDescriptor(
          'const_equals',
          'const f =',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
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
          ParserErrorCode.expectedToken,
        ], 'const f = 0;'),
        //
        // Instance field, final.
        //
        TestDescriptor(
          'final_noName',
          'final',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
          'final _s_;',
          failing: allExceptAnnotationAndEof,
        ),
        TestDescriptor(
          'final_name',
          'final f',
          [ParserErrorCode.expectedToken],
          'final f;',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'final_equals',
          'final f =',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
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
          ParserErrorCode.expectedToken,
        ], 'final f = 0;'),
        //
        // Instance field, var.
        //
        TestDescriptor(
          'var_noName',
          'var',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
          'var _s_;',
          failing: allExceptAnnotationAndEof,
        ),
        TestDescriptor(
          'var_name',
          'var f',
          [ParserErrorCode.expectedToken],
          'var f;',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'var_name_comma',
          'var f,',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
          'var f, _s_;',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'var_equals',
          'var f =',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
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
          ParserErrorCode.expectedToken,
        ], 'var f = 0;'),
        //
        // Instance field, type.
        //
        TestDescriptor(
          'type_noName',
          'A',
          [
            ParserErrorCode.missingConstFinalVarOrType,
            ParserErrorCode.expectedToken,
          ],
          'A _s_;',
          allFailing: true,
        ),
        TestDescriptor('type_name', 'A f', [
          ParserErrorCode.expectedToken,
        ], 'A f;'),
        TestDescriptor(
          'type_name_comma',
          'A f,',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
          'A f, _s_;',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'type_equals',
          'A f =',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
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
          ParserErrorCode.expectedToken,
        ], 'A f = 0;'),
        //
        // Static field, const.
        //
        TestDescriptor(
          'static_const_noName',
          'static const',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
          'static const _s_;',
          failing: allExceptAnnotationAndEof,
          expectedDiagnosticsInValidCode: [
            CompileTimeErrorCode.constNotInitialized,
          ],
        ),
        TestDescriptor(
          'static_const_name',
          'static const f',
          [
            ParserErrorCode.expectedToken,
            CompileTimeErrorCode.constNotInitialized,
          ],
          'static const f;',
          failing: ['methodNonVoid', 'getter', 'setter'],
          expectedDiagnosticsInValidCode: [
            CompileTimeErrorCode.constNotInitialized,
          ],
        ),
        TestDescriptor(
          'static_const_equals',
          'static const f =',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
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
          ParserErrorCode.expectedToken,
        ], 'static const f = 0;'),
        //
        // Static field, final.
        //
        TestDescriptor(
          'static_final_noName',
          'static final',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
          'static final _s_;',
          failing: allExceptAnnotationAndEof,
        ),
        TestDescriptor(
          'static_final_name',
          'static final f',
          [ParserErrorCode.expectedToken],
          'static final f;',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'static_final_equals',
          'static final f =',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
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
          ParserErrorCode.expectedToken,
        ], 'static final f = 0;'),
        //
        // Static field, var.
        //
        TestDescriptor(
          'static_var_noName',
          'static var',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
          'static var _s_;',
          failing: allExceptAnnotationAndEof,
        ),
        TestDescriptor(
          'static_var_name',
          'static var f',
          [ParserErrorCode.expectedToken],
          'static var f;',
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'static_var_equals',
          'static var f =',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
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
          ParserErrorCode.expectedToken,
        ], 'static var f = 0;'),
        //
        // Static field, type.
        //
        TestDescriptor(
          'static_type_noName',
          'static A',
          [
            ParserErrorCode.missingConstFinalVarOrType,
            ParserErrorCode.expectedToken,
          ],
          'static A _s_;',
          allFailing: true,
        ),
        TestDescriptor('static_type_name', 'static A f', [
          ParserErrorCode.expectedToken,
        ], 'static A f;'),
        TestDescriptor(
          'static_type_equals',
          'static A f =',
          [ParserErrorCode.missingIdentifier, ParserErrorCode.expectedToken],
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
          ParserErrorCode.expectedToken,
        ], 'static A f = 0;'),
      ],
      PartialCodeTest.classMemberSuffixes,
      head: 'class C { ',
      tail: ' }',
    );
  }
}
