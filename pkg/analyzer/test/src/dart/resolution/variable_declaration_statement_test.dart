// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VariableDeclarationStatementResolutionTest);
  });
}

@reflectiveTest
class VariableDeclarationStatementResolutionTest
    extends PubPackageResolutionTest {
  test_initializer_super() async {
    await assertErrorsInCode(r'''
class A {
  void f() {
    final a = super;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 33, 1),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 37, 5),
    ]);

    final node = findNode.singleVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
VariableDeclarationStatement
  variables: VariableDeclarationList
    keyword: final
    variables
      VariableDeclaration
        name: a
        equals: =
        initializer: SuperExpression
          superKeyword: super
          staticType: A
        declaredElement: hasImplicitType isFinal a@33
          type: A
  semicolon: ;
''');
  }

  test_initializer_this() async {
    await assertErrorsInCode(r'''
class A {
  void f() {
    final a = this;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 33, 1),
    ]);

    final node = findNode.singleVariableDeclarationStatement;
    assertResolvedNodeText(node, r'''
VariableDeclarationStatement
  variables: VariableDeclarationList
    keyword: final
    variables
      VariableDeclaration
        name: a
        equals: =
        initializer: ThisExpression
          thisKeyword: this
          staticType: A
        declaredElement: hasImplicitType isFinal a@33
          type: A
  semicolon: ;
''');
  }
}
