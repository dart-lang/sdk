// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(VariableDeclarationStatementResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class VariableDeclarationStatementResolutionTest
    extends PubPackageResolutionTest {
  test_initializer_super() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void f() {
    final a = super;
//        ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//            ^^^^^
// [diag.missingAssignableSelector] Missing selector such as '.identifier' or '[0]'.
  }
}
''');

    var node = result.findNode.singleVariableDeclarationStatement;
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
        declaredFragment: isFinal isPublic a@33
          element: hasImplicitType isFinal isPublic
            type: A
  semicolon: ;
''');
  }

  test_initializer_this() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  void f() {
    final a = this;
//        ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
  }
}
''');

    var node = result.findNode.singleVariableDeclarationStatement;
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
        declaredFragment: isFinal isPublic a@33
          element: hasImplicitType isFinal isPublic
            type: A
  semicolon: ;
''');
  }
}
