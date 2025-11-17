// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;

import 'partial_code_support.dart';

main() {
  ConstructorTest().buildAll();
}

class ConstructorTest extends PartialCodeTest {
  buildAll() {
    buildTests(
      'constructor',
      [
        TestDescriptor(
          'colon',
          'C() :',
          [diag.missingInitializer, diag.missingFunctionBody],
          'C() : _s_ = _s_ {}',
          adjustValidUnitBeforeComparison: setSeparator,
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'colon_field',
          'C() : f',
          [diag.missingAssignmentInInitializer, diag.missingFunctionBody],
          'C() : f = _s_ {}',
          adjustValidUnitBeforeComparison: setSeparator,
        ),
        TestDescriptor(
          'colon_field_increment',
          'C() : f++',
          [diag.missingAssignmentInInitializer, diag.missingFunctionBody],
          'C() : _s_ = f++ {}',
          adjustValidUnitBeforeComparison: setSeparator,
        ),
        TestDescriptor(
          'colon_field_comma',
          'C() : f = 0,',
          [diag.missingInitializer, diag.missingFunctionBody],
          'C() : f = 0, _s_ = _s_ {}',
          adjustValidUnitBeforeComparison: setSeparator,
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'colon_block',
          'C() : {}',
          [diag.missingInitializer],
          'C() : _s_ = _s_ {}',
          adjustValidUnitBeforeComparison: setSeparator,
        ),
        TestDescriptor(
          'colon_semicolon',
          'C() : ;',
          [diag.missingInitializer],
          'C() : _s_ = _s_ ;',
          adjustValidUnitBeforeComparison: setSeparator,
        ),
        TestDescriptor('super', 'C() : super', [
          diag.expectedToken,
          diag.missingFunctionBody,
        ], 'C() : super() {}'),
        TestDescriptor(
          'super_dot',
          'C() : super.',
          [
            diag.expectedToken,
            diag.missingIdentifier,
            diag.missingFunctionBody,
          ],
          'C() : super._s_() {}',
          failing: ['fieldConst', 'methodNonVoid', 'getter', 'setter'],
        ),
        TestDescriptor(
          'super_qdot',
          'C() : super?.',
          [
            diag.invalidOperatorQuestionmarkPeriodForSuper,
            diag.expectedToken,
            diag.missingFunctionBody,
          ],
          'C() : super?._s_() {}',
          expectedDiagnosticsInValidCode: [
            diag.invalidOperatorQuestionmarkPeriodForSuper,
          ],
          failing: ['methodNonVoid', 'getter', 'setter'],
        ),
      ],
      PartialCodeTest.classMemberSuffixes,
      head: 'class C {',
      tail: '}',
    );
  }

  CompilationUnitImpl setSeparator(CompilationUnitImpl unit) {
    var declaration = unit.declarations[0] as ClassDeclaration;
    var classBody = declaration.body as BlockClassBody;
    var member = classBody.members[0] as ConstructorDeclarationImpl;
    member.separator = Token(
      TokenType.COLON,
      member.parameters.endToken.charOffset + 1,
    );
    return unit;
  }
}
