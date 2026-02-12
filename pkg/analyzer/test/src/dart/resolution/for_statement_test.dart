// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(
      ForStatementResolutionTest_ForEachPartsWithDeclaration,
    );
    defineReflectiveTests(
      ForStatementResolutionTest_ForEachPartsWithIdentifier,
    );
    defineReflectiveTests(ForStatementResolutionTest_ForEachPartsWithPattern);
    defineReflectiveTests(ForStatementResolutionTest_ForPartsWithExpression);
    defineReflectiveTests(ForStatementResolutionTest_ForPartsWithDeclarations);
    defineReflectiveTests(ForStatementResolutionTest_ForPartsWithPattern);
  });
}

// TODO(scheglov): Move other for-in tests here.
@reflectiveTest
class ForStatementResolutionTest_ForEachPartsWithDeclaration
    extends PubPackageResolutionTest {
  test_async_loopVariable_var_stream() async {
    await resolveTestCode(r'''
void f(Stream<int> values) async {
  await for (var v in values) {
    v;
  }
}''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: v
      declaredFragment: isPublic v@52
        element: hasImplicitType isPublic
          type: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      element: <testLibrary>::@function::f::@formalParameter::values
      staticType: Stream<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          element: v@52
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_async_scope_afterLoop_uses_outer_despite_loopVariable() async {
    await assertErrorsInCode(
      r'''
void f(Stream<int> x, int i) async {
  await for (var i in x) {}
  i;
}
''',
      [error(diag.unusedLocalVariable, 54, 1)],
    );

    var node = findNode.singleBlockFunctionBody;
    assertResolvedNodeText(node, r'''
BlockFunctionBody
  keyword: async
  block: Block
    leftBracket: {
    statements
      ForStatement
        awaitKeyword: await
        forKeyword: for
        leftParenthesis: (
        forLoopParts: ForEachPartsWithDeclaration
          loopVariable: DeclaredIdentifier
            keyword: var
            name: i
            declaredFragment: isPublic i@54
              element: hasImplicitType isPublic
                type: int
          inKeyword: in
          iterable: SimpleIdentifier
            token: x
            element: <testLibrary>::@function::f::@formalParameter::x
            staticType: Stream<int>
        rightParenthesis: )
        body: Block
          leftBracket: {
          rightBracket: }
      ExpressionStatement
        expression: SimpleIdentifier
          token: i
          element: <testLibrary>::@function::f::@formalParameter::i
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_async_scope_loopVariable_shadows_numType() async {
    await assertNoErrorsInCode(r'''
void f(Stream<int> values) async {
  await for (var num in values) {
    num;
  }
}
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: num
      declaredFragment: isPublic num@52
        element: hasImplicitType isPublic
          type: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      element: <testLibrary>::@function::f::@formalParameter::values
      staticType: Stream<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: num
          element: num@52
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_iterable_contextType() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  for (int v in g()) {}
}

T g<T>() => throw 0;
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      type: NamedType
        name: int
        element: dart:core::@class::int
        type: int
      name: v
      declaredFragment: isPublic v@56
        element: isPublic
          type: int
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Iterable<int> Function()
      staticType: Iterable<int>
      typeArgumentTypes
        Iterable<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_sync_iterable_dynamic() async {
    await assertErrorsInCode(
      r'''
void f(dynamic values) {
  for (var v in values) {}
}
''',
      [error(diag.unusedLocalVariable, 36, 1)],
    );

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: v
      declaredFragment: isPublic v@36
        element: hasImplicitType isPublic
          type: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      element: <testLibrary>::@function::f::@formalParameter::values
      staticType: dynamic
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_sync_iterable_missing() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (var v in) {
    v;
  }
}
''',
      [error(diag.missingIdentifier, 26, 1)],
    );

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: v
      declaredFragment: isPublic v@22
        element: hasImplicitType isPublic
          type: InvalidType
    inKeyword: in
    iterable: SimpleIdentifier
      token: <empty> <synthetic>
      element: <null>
      staticType: InvalidType
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          element: v@22
          staticType: InvalidType
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_iterable_nullable() async {
    await assertErrorsInCode(
      r'''
void f(Iterable<int>? values) {
  for (var v in values) {
    v;
  }
}
''',
      [error(diag.uncheckedUseOfNullableValueAsIterator, 48, 6)],
    );

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: v
      declaredFragment: isPublic v@43
        element: hasImplicitType isPublic
          type: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      element: <testLibrary>::@function::f::@formalParameter::values
      staticType: Iterable<int>?
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          element: v@43
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_iterable_object() async {
    await assertErrorsInCode(
      r'''
void f(Object values) {
  for (var v in values) {
    v;
  }
}
''',
      [error(diag.forInOfInvalidType, 40, 6)],
    );

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: v
      declaredFragment: isPublic v@35
        element: hasImplicitType isPublic
          type: InvalidType
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      element: <testLibrary>::@function::f::@formalParameter::values
      staticType: Object
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          element: v@35
          staticType: InvalidType
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_iterable_super() async {
    await assertErrorsInCode(
      r'''
abstract class A implements Iterable<int> {
  void f() {
    for (var v in super) {}
  }
}
''',
      [
        error(diag.unusedLocalVariable, 70, 1),
        error(diag.missingAssignableSelector, 75, 5),
      ],
    );

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: v
      declaredFragment: isPublic v@70
        element: hasImplicitType isPublic
          type: int
    inKeyword: in
    iterable: SuperExpression
      superKeyword: super
      staticType: A
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_sync_loopVariable_dynamic() async {
    await resolveTestCode(r'''
void f(List<int> values) {
  for (dynamic v in values) {
    v;
  }
}''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      type: NamedType
        name: dynamic
        element: dynamic
        type: dynamic
      name: v
      declaredFragment: isPublic v@42
        element: isPublic
          type: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      element: <testLibrary>::@function::f::@formalParameter::values
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          element: v@42
          staticType: dynamic
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_loopVariable_var_genericFunction() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  for (var v in g()) {}
}

T g<T>() => throw 0;
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: v
      declaredFragment: isPublic v@56
        element: hasImplicitType isPublic
          type: Object?
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Iterable<Object?> Function()
      staticType: Iterable<Object?>
      typeArgumentTypes
        Iterable<Object?>
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_sync_loopVariable_var_iterable() async {
    await resolveTestCode(r'''
void f(Iterable<int> values) {
  for (var v in values) {
    v;
  }
}
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: v
      declaredFragment: isPublic v@42
        element: hasImplicitType isPublic
          type: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      element: <testLibrary>::@function::f::@formalParameter::values
      staticType: Iterable<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          element: v@42
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_loopVariable_var_list() async {
    await resolveTestCode(r'''
void f(List<int> values) {
  for (var v in values) {
    v;
  }
}
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: v
      declaredFragment: isPublic v@38
        element: hasImplicitType isPublic
          type: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      element: <testLibrary>::@function::f::@formalParameter::values
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          element: v@38
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_scope_afterLoop_uses_outer_despite_loopVariable() async {
    await assertErrorsInCode(
      r'''
void f(List<int> x, int i) {
  for (var i in x) {}
  i;
}
''',
      [error(diag.unusedLocalVariable, 40, 1)],
    );

    var node = findNode.singleBlockFunctionBody;
    assertResolvedNodeText(node, r'''
BlockFunctionBody
  block: Block
    leftBracket: {
    statements
      ForStatement
        forKeyword: for
        leftParenthesis: (
        forLoopParts: ForEachPartsWithDeclaration
          loopVariable: DeclaredIdentifier
            keyword: var
            name: i
            declaredFragment: isPublic i@40
              element: hasImplicitType isPublic
                type: int
          inKeyword: in
          iterable: SimpleIdentifier
            token: x
            element: <testLibrary>::@function::f::@formalParameter::x
            staticType: List<int>
        rightParenthesis: )
        body: Block
          leftBracket: {
          rightBracket: }
      ExpressionStatement
        expression: SimpleIdentifier
          token: i
          element: <testLibrary>::@function::f::@formalParameter::i
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_scope_body_shadows_loopVariable() async {
    await assertErrorsInCode(
      r'''
void f(List<int> values) {
  for (var i in values) {
    var i = 'a';
    i;
  }
}
''',
      [error(diag.unusedLocalVariable, 38, 1)],
    );

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: i
      declaredFragment: isPublic i@38
        element: hasImplicitType isPublic
          type: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      element: <testLibrary>::@function::f::@formalParameter::values
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      VariableDeclarationStatement
        variables: VariableDeclarationList
          keyword: var
          variables
            VariableDeclaration
              name: i
              equals: =
              initializer: SimpleStringLiteral
                literal: 'a'
              declaredFragment: isPublic i@61
                element: hasImplicitType isPublic
                  type: String
        semicolon: ;
      ExpressionStatement
        expression: SimpleIdentifier
          token: i
          element: i@61
          staticType: String
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_scope_iterable_uses_outer() async {
    await assertNoErrorsInCode(r'''
void f(List<int> i) {
  for (var i in i) {
    i;
  }
}
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: i
      declaredFragment: isPublic i@33
        element: hasImplicitType isPublic
          type: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: i
      element: <testLibrary>::@function::f::@formalParameter::i
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: i
          element: i@33
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_scope_loopVariable_shadows_numType() async {
    await assertNoErrorsInCode(r'''
void f(List<int> values) {
  for (var num in values) {
    num;
  }
}
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: num
      declaredFragment: isPublic num@38
        element: hasImplicitType isPublic
          type: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      element: <testLibrary>::@function::f::@formalParameter::values
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: num
          element: num@38
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_type_genericFunctionType() async {
    await assertNoErrorsInCode(r'''
void f() {
  for (Null Function<T>(T, Null) e in <dynamic>[]) {
    e;
  }
}
''');
  }
}

@reflectiveTest
class ForStatementResolutionTest_ForEachPartsWithIdentifier
    extends PubPackageResolutionTest {
  test_async_iterable_stream() async {
    await assertNoErrorsInCode(r'''
void f(v, Stream<int> values) async {
  await for (v in values) {
    v;
  }
}
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithIdentifier
    identifier: SimpleIdentifier
      token: v
      element: <testLibrary>::@function::f::@formalParameter::v
      staticType: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      element: <testLibrary>::@function::f::@formalParameter::values
      staticType: Stream<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          element: <testLibrary>::@function::f::@formalParameter::v
          staticType: dynamic
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_iterable_contextType_fromInstanceSetter() async {
    await assertNoErrorsInCode(r'''
T g<T>() => throw 0;

class C {
  set x(int value) {}

  void f() {
    for (x in g()) {}
  }
}
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithIdentifier
    identifier: SimpleIdentifier
      token: x
      element: <testLibrary>::@class::C::@setter::x
      staticType: int
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Iterable<int> Function()
      staticType: Iterable<int>
      typeArgumentTypes
        Iterable<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_sync_iterable_contextType_fromTopLevelSetter() async {
    await assertNoErrorsInCode(r'''
T g<T>() => throw 0;

set x(int value) {}

void f() {
  for (x in g()) {}
}
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithIdentifier
    identifier: SimpleIdentifier
      token: x
      element: <testLibrary>::@setter::x
      staticType: int
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Iterable<int> Function()
      staticType: Iterable<int>
      typeArgumentTypes
        Iterable<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_sync_iterable_list() async {
    await assertNoErrorsInCode(r'''
void f(v, List<int> values) {
  for (v in values) {
    v;
  }
}
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithIdentifier
    identifier: SimpleIdentifier
      token: v
      element: <testLibrary>::@function::f::@formalParameter::v
      staticType: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      element: <testLibrary>::@function::f::@formalParameter::values
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          element: <testLibrary>::@function::f::@formalParameter::v
          staticType: dynamic
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_iterable_super() async {
    await assertErrorsInCode(
      r'''
abstract class A implements Iterable<int> {
  void f(v) {
    for (v in super) {}
  }
}
''',
      [error(diag.missingAssignableSelector, 72, 5)],
    );
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithIdentifier
    identifier: SimpleIdentifier
      token: v
      element: <testLibrary>::@class::A::@method::f::@formalParameter::v
      staticType: dynamic
    inKeyword: in
    iterable: SuperExpression
      superKeyword: super
      staticType: A
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_sync_scope_afterLoop_uses_outer() async {
    await assertNoErrorsInCode(r'''
void f(dynamic v, List<int> values) {
  for (v in values) {
    v;
  }
  v;
}
''');

    var node = findNode.singleBlockFunctionBody;
    assertResolvedNodeText(node, r'''
BlockFunctionBody
  block: Block
    leftBracket: {
    statements
      ForStatement
        forKeyword: for
        leftParenthesis: (
        forLoopParts: ForEachPartsWithIdentifier
          identifier: SimpleIdentifier
            token: v
            element: <testLibrary>::@function::f::@formalParameter::v
            staticType: dynamic
          inKeyword: in
          iterable: SimpleIdentifier
            token: values
            element: <testLibrary>::@function::f::@formalParameter::values
            staticType: List<int>
        rightParenthesis: )
        body: Block
          leftBracket: {
          statements
            ExpressionStatement
              expression: SimpleIdentifier
                token: v
                element: <testLibrary>::@function::f::@formalParameter::v
                staticType: dynamic
              semicolon: ;
          rightBracket: }
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          element: <testLibrary>::@function::f::@formalParameter::v
          staticType: dynamic
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_scope_header_not_affected_by_body_shadowing() async {
    await assertNoErrorsInCode(r'''
void f(dynamic v, List<int> values) {
  for (v in values) {
    var v = 0;
    v;
  }
}
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithIdentifier
    identifier: SimpleIdentifier
      token: v
      element: <testLibrary>::@function::f::@formalParameter::v
      staticType: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      element: <testLibrary>::@function::f::@formalParameter::values
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      VariableDeclarationStatement
        variables: VariableDeclarationList
          keyword: var
          variables
            VariableDeclaration
              name: v
              equals: =
              initializer: IntegerLiteral
                literal: 0
                staticType: int
              declaredFragment: isPublic v@68
                element: hasImplicitType isPublic
                  type: int
        semicolon: ;
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          element: v@68
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_scope_iterable_uses_outer() async {
    await assertNoErrorsInCode(r'''
void f(dynamic v) {
  for (v in v) {}
}
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithIdentifier
    identifier: SimpleIdentifier
      token: v
      element: <testLibrary>::@function::f::@formalParameter::v
      staticType: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: v
      element: <testLibrary>::@function::f::@formalParameter::v
      staticType: dynamic
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }
}

@reflectiveTest
class ForStatementResolutionTest_ForEachPartsWithPattern
    extends PubPackageResolutionTest {
  test_async_iterable_contextType_patternVariable_typed() async {
    await assertNoErrorsInCode(r'''
void f() async {
  await for (var (int a) in g()) {
    a;
  }
}

T g<T>() => throw 0;
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: a
        declaredFragment: isPublic a@39
          element: isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Stream<int> Function()
      staticType: Stream<int>
      typeArgumentTypes
        Stream<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@39
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_async_iterable_contextType_patternVariable_untyped() async {
    await assertNoErrorsInCode(r'''
void f() async {
  await for (var (a) in g()) {
    a;
  }
}

T g<T>() => throw 0;
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@35
          element: hasImplicitType isPublic
            type: Object?
        matchedValueType: Object?
      rightParenthesis: )
      matchedValueType: Object?
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Stream<Object?> Function()
      staticType: Stream<Object?>
      typeArgumentTypes
        Stream<Object?>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@35
          staticType: Object?
        semicolon: ;
    rightBracket: }
''');
  }

  test_async_iterable_dynamic() async {
    await assertNoErrorsInCode(r'''
void f(x) async {
  await for (var (a) in x) {
    a;
  }
}
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@36
          element: hasImplicitType isPublic
            type: dynamic
        matchedValueType: dynamic
      rightParenthesis: )
      matchedValueType: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: dynamic
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@36
          staticType: dynamic
        semicolon: ;
    rightBracket: }
''');
  }

  test_async_iterable_object() async {
    await assertErrorsInCode(
      r'''
void f(Object x) async {
  await for (var (a) in x) {
    a;
  }
}
''',
      [error(diag.forInOfInvalidType, 49, 1)],
    );
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@43
          element: hasImplicitType isPublic
            type: InvalidType
        matchedValueType: InvalidType
      rightParenthesis: )
      matchedValueType: InvalidType
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Object
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@43
          staticType: InvalidType
        semicolon: ;
    rightBracket: }
''');
  }

  test_async_iterable_stream() async {
    await assertNoErrorsInCode(r'''
void f(Stream<int> x) async {
  await for (var (a) in x) {
    a;
  }
}
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@48
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Stream<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@48
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_async_iterable_stream_wildcard() async {
    await assertNoErrorsInCode(r'''
void f(Stream<int> x) async {
  await for (var (_) in x) {}
}
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: WildcardPattern
        name: _
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Stream<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_async_keyword_final_patternVariable() async {
    await assertNoErrorsInCode(r'''
void f(Stream<int> x) async {
  await for (final (a) in x) {
    a;
  }
}
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: final
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isFinal isPublic a@50
          element: hasImplicitType isFinal isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Stream<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@50
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_async_pattern_patternVariable_typed() async {
    await assertNoErrorsInCode(r'''
void f(Stream<int> x) async {
  await for (var (num a) in x) {
    a;
  }
}
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        type: NamedType
          name: num
          element: dart:core::@class::num
          type: num
        name: a
        declaredFragment: isPublic a@52
          element: isPublic
            type: num
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Stream<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@52
          staticType: num
        semicolon: ;
    rightBracket: }
''');
  }

  test_async_scope_afterLoop_uses_outer_despite_patternVariable() async {
    await assertErrorsInCode(
      r'''
void f(Stream<int> x, int a) async {
  await for (var (a) in x) {}
  a;
}
''',
      [error(diag.unusedLocalVariable, 55, 1)],
    );

    var node = findNode.singleBlockFunctionBody;
    assertResolvedNodeText(node, r'''
BlockFunctionBody
  keyword: async
  block: Block
    leftBracket: {
    statements
      ForStatement
        awaitKeyword: await
        forKeyword: for
        leftParenthesis: (
        forLoopParts: ForEachPartsWithPattern
          keyword: var
          pattern: ParenthesizedPattern
            leftParenthesis: (
            pattern: DeclaredVariablePattern
              name: a
              declaredFragment: isPublic a@55
                element: hasImplicitType isPublic
                  type: int
              matchedValueType: int
            rightParenthesis: )
            matchedValueType: int
          inKeyword: in
          iterable: SimpleIdentifier
            token: x
            element: <testLibrary>::@function::f::@formalParameter::x
            staticType: Stream<int>
        rightParenthesis: )
        body: Block
          leftBracket: {
          rightBracket: }
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_async_scope_body_shadows_patternVariable() async {
    await assertErrorsInCode(
      r'''
void f(Stream<int> x) async {
  await for (var (a) in x) {
    var a = 1;
    a;
  }
}
''',
      [error(diag.unusedLocalVariable, 48, 1)],
    );

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@48
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Stream<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      VariableDeclarationStatement
        variables: VariableDeclarationList
          keyword: var
          variables
            VariableDeclaration
              name: a
              equals: =
              initializer: IntegerLiteral
                literal: 1
                staticType: int
              declaredFragment: isPublic a@67
                element: hasImplicitType isPublic
                  type: int
        semicolon: ;
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@67
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_async_scope_iterable_uses_outer() async {
    await assertNoErrorsInCode(r'''
void f(Stream<int> x) async {
  await for (var (x) in x) {
    x;
  }
}
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  awaitKeyword: await
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: x
        declaredFragment: isPublic x@48
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Stream<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: x
          element: x@48
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_iterable_contextType_patternVariable_typed() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (var (int a) in g()) {}
}

T g<T>() => throw 0;
''',
      [error(diag.unusedLocalVariable, 27, 1)],
    );
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: a
        declaredFragment: isPublic a@27
          element: isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Iterable<int> Function()
      staticType: Iterable<int>
      typeArgumentTypes
        Iterable<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_sync_iterable_contextType_patternVariable_untyped() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (var (a) in g()) {}
}

T g<T>() => throw 0;
''',
      [error(diag.unusedLocalVariable, 23, 1)],
    );
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@23
          element: hasImplicitType isPublic
            type: Object?
        matchedValueType: Object?
      rightParenthesis: )
      matchedValueType: Object?
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        element: <testLibrary>::@function::g
        staticType: T Function<T>()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticInvokeType: Iterable<Object?> Function()
      staticType: Iterable<Object?>
      typeArgumentTypes
        Iterable<Object?>
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_sync_iterable_dynamic() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  for (var (a) in x) {
    a;
  }
}
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@24
          element: hasImplicitType isPublic
            type: dynamic
        matchedValueType: dynamic
      rightParenthesis: )
      matchedValueType: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: dynamic
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@24
          staticType: dynamic
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_iterable_list() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  for (var (a) in x) {
    a;
  }
}
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@34
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@34
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_iterable_list_wildcard() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  for (var (_) in x) {}
}
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: WildcardPattern
        name: _
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_sync_iterable_object() async {
    await assertErrorsInCode(
      r'''
void f(Object x) {
  for (var (a) in x) {
    a;
  }
}
''',
      [error(diag.forInOfInvalidType, 37, 1)],
    );
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@31
          element: hasImplicitType isPublic
            type: InvalidType
        matchedValueType: InvalidType
      rightParenthesis: )
      matchedValueType: InvalidType
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: Object
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@31
          staticType: InvalidType
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_iterable_super() async {
    await assertErrorsInCode(
      r'''
abstract class A implements Iterable<int> {
  void f() {
    for (var (a) in super) {}
  }
}
''',
      [
        error(diag.unusedLocalVariable, 71, 1),
        error(diag.missingAssignableSelector, 77, 5),
      ],
    );
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@71
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SuperExpression
      superKeyword: super
      staticType: A
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_sync_keyword_final_patternVariable() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  for (final (a) in x) {
    a;
  }
}
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: final
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isFinal isPublic a@36
          element: hasImplicitType isFinal isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@36
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_pattern_patternVariable_typed() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  for (var (num a) in x) {
    a;
  }
}
''');
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        type: NamedType
          name: num
          element: dart:core::@class::num
          type: num
        name: a
        declaredFragment: isPublic a@38
          element: isPublic
            type: num
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@38
          staticType: num
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_scope_afterLoop_uses_outer_despite_patternVariable() async {
    await assertErrorsInCode(
      r'''
void f(List<int> x, int a) {
  for (var (a) in x) {}
  a;
}
''',
      [error(diag.unusedLocalVariable, 41, 1)],
    );

    var node = findNode.singleBlockFunctionBody;
    assertResolvedNodeText(node, r'''
BlockFunctionBody
  block: Block
    leftBracket: {
    statements
      ForStatement
        forKeyword: for
        leftParenthesis: (
        forLoopParts: ForEachPartsWithPattern
          keyword: var
          pattern: ParenthesizedPattern
            leftParenthesis: (
            pattern: DeclaredVariablePattern
              name: a
              declaredFragment: isPublic a@41
                element: hasImplicitType isPublic
                  type: int
              matchedValueType: int
            rightParenthesis: )
            matchedValueType: int
          inKeyword: in
          iterable: SimpleIdentifier
            token: x
            element: <testLibrary>::@function::f::@formalParameter::x
            staticType: List<int>
        rightParenthesis: )
        body: Block
          leftBracket: {
          rightBracket: }
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_scope_body_shadows_patternVariable() async {
    await assertErrorsInCode(
      r'''
void f(List<int> x) {
  for (var (a) in x) {
    var a = 1;
    a;
  }
}
''',
      [error(diag.unusedLocalVariable, 34, 1)],
    );

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isPublic a@34
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      VariableDeclarationStatement
        variables: VariableDeclarationList
          keyword: var
          variables
            VariableDeclaration
              name: a
              equals: =
              initializer: IntegerLiteral
                literal: 1
                staticType: int
              declaredFragment: isPublic a@53
                element: hasImplicitType isPublic
                  type: int
        semicolon: ;
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@53
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_sync_scope_iterable_uses_outer() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  for (var (x) in x) {
    x;
  }
}
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: x
        declaredFragment: isPublic x@34
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      element: <testLibrary>::@function::f::@formalParameter::x
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: x
          element: x@34
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }
}

@reflectiveTest
class ForStatementResolutionTest_ForPartsWithDeclarations
    extends PubPackageResolutionTest {
  test_scope_afterLoop_uses_outer_despite_initializerVariable() async {
    await assertNoErrorsInCode(r'''
void f(int i) {
  for (var i = 0; i < 1; i++) {}
  i;
}
''');

    var node = findNode.singleBlockFunctionBody;
    assertResolvedNodeText(node, r'''
BlockFunctionBody
  block: Block
    leftBracket: {
    statements
      ForStatement
        forKeyword: for
        leftParenthesis: (
        forLoopParts: ForPartsWithDeclarations
          variables: VariableDeclarationList
            keyword: var
            variables
              VariableDeclaration
                name: i
                equals: =
                initializer: IntegerLiteral
                  literal: 0
                  staticType: int
                declaredFragment: isPublic i@27
                  element: hasImplicitType isPublic
                    type: int
          leftSeparator: ;
          condition: BinaryExpression
            leftOperand: SimpleIdentifier
              token: i
              element: i@27
              staticType: int
            operator: <
            rightOperand: IntegerLiteral
              literal: 1
              correspondingParameter: dart:core::@class::num::@method::<::@formalParameter::other
              staticType: int
            element: dart:core::@class::num::@method::<
            staticInvokeType: bool Function(num)
            staticType: bool
          rightSeparator: ;
          updaters
            PostfixExpression
              operand: SimpleIdentifier
                token: i
                element: i@27
                staticType: null
              operator: ++
              readElement: i@27
              readType: int
              writeElement: i@27
              writeType: int
              element: dart:core::@class::num::@method::+
              staticType: int
        rightParenthesis: )
        body: Block
          leftBracket: {
          rightBracket: }
      ExpressionStatement
        expression: SimpleIdentifier
          token: i
          element: <testLibrary>::@function::f::@formalParameter::i
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_scope_body_shadows_loopVariable() async {
    await assertNoErrorsInCode(r'''
void f(List<int> i) {
  for (var i = 0; i < 10; ++i) {
    var i = 'a';
    i;
  }
}
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithDeclarations
    variables: VariableDeclarationList
      keyword: var
      variables
        VariableDeclaration
          name: i
          equals: =
          initializer: IntegerLiteral
            literal: 0
            staticType: int
          declaredFragment: isPublic i@33
            element: hasImplicitType isPublic
              type: int
    leftSeparator: ;
    condition: BinaryExpression
      leftOperand: SimpleIdentifier
        token: i
        element: i@33
        staticType: int
      operator: <
      rightOperand: IntegerLiteral
        literal: 10
        correspondingParameter: dart:core::@class::num::@method::<::@formalParameter::other
        staticType: int
      element: dart:core::@class::num::@method::<
      staticInvokeType: bool Function(num)
      staticType: bool
    rightSeparator: ;
    updaters
      PrefixExpression
        operator: ++
        operand: SimpleIdentifier
          token: i
          element: i@33
          staticType: null
        readElement: i@33
        readType: int
        writeElement: i@33
        writeType: int
        element: dart:core::@class::num::@method::+
        staticType: int
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      VariableDeclarationStatement
        variables: VariableDeclarationList
          keyword: var
          variables
            VariableDeclaration
              name: i
              equals: =
              initializer: SimpleStringLiteral
                literal: 'a'
              declaredFragment: isPublic i@63
                element: hasImplicitType isPublic
                  type: String
        semicolon: ;
      ExpressionStatement
        expression: SimpleIdentifier
          token: i
          element: i@63
          staticType: String
        semicolon: ;
    rightBracket: }
''');
  }

  test_scope_initializerVariable_visibleInBody() async {
    await assertNoErrorsInCode(r'''
void f() {
  for (var i = 0; i < 10; i++) {
    i;
  }
}
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithDeclarations
    variables: VariableDeclarationList
      keyword: var
      variables
        VariableDeclaration
          name: i
          equals: =
          initializer: IntegerLiteral
            literal: 0
            staticType: int
          declaredFragment: isPublic i@22
            element: hasImplicitType isPublic
              type: int
    leftSeparator: ;
    condition: BinaryExpression
      leftOperand: SimpleIdentifier
        token: i
        element: i@22
        staticType: int
      operator: <
      rightOperand: IntegerLiteral
        literal: 10
        correspondingParameter: dart:core::@class::num::@method::<::@formalParameter::other
        staticType: int
      element: dart:core::@class::num::@method::<
      staticInvokeType: bool Function(num)
      staticType: bool
    rightSeparator: ;
    updaters
      PostfixExpression
        operand: SimpleIdentifier
          token: i
          element: i@22
          staticType: null
        operator: ++
        readElement: i@22
        readType: int
        writeElement: i@22
        writeType: int
        element: dart:core::@class::num::@method::+
        staticType: int
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: i
          element: i@22
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_scope_variables_initializer_uses_outer_sameName() async {
    await assertErrorsInCode(
      r'''
void f(int i) {
  for (var i = i; i < 1; i++) {}
}
''',
      [
        error(
          diag.referencedBeforeDeclaration,
          31,
          1,
          contextMessages: [message(testFile, 27, 1)],
        ),
      ],
    );

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithDeclarations
    variables: VariableDeclarationList
      keyword: var
      variables
        VariableDeclaration
          name: i
          equals: =
          initializer: SimpleIdentifier
            token: i
            element: i@27
            staticType: dynamic
          declaredFragment: isPublic i@27
            element: hasImplicitType isPublic
              type: dynamic
    leftSeparator: ;
    condition: BinaryExpression
      leftOperand: SimpleIdentifier
        token: i
        element: i@27
        staticType: dynamic
      operator: <
      rightOperand: IntegerLiteral
        literal: 1
        correspondingParameter: <null>
        staticType: int
      element: <null>
      staticInvokeType: null
      staticType: dynamic
    rightSeparator: ;
    updaters
      PostfixExpression
        operand: SimpleIdentifier
          token: i
          element: i@27
          staticType: null
        operator: ++
        readElement: i@27
        readType: dynamic
        writeElement: i@27
        writeType: dynamic
        element: <null>
        staticType: dynamic
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_scope_variables_uses_outer() async {
    await assertNoErrorsInCode(r'''
void f(int i) {
  for (var i2 = i; i2 < 10; ++i2) {}
}
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithDeclarations
    variables: VariableDeclarationList
      keyword: var
      variables
        VariableDeclaration
          name: i2
          equals: =
          initializer: SimpleIdentifier
            token: i
            element: <testLibrary>::@function::f::@formalParameter::i
            staticType: int
          declaredFragment: isPublic i2@27
            element: hasImplicitType isPublic
              type: int
    leftSeparator: ;
    condition: BinaryExpression
      leftOperand: SimpleIdentifier
        token: i2
        element: i2@27
        staticType: int
      operator: <
      rightOperand: IntegerLiteral
        literal: 10
        correspondingParameter: dart:core::@class::num::@method::<::@formalParameter::other
        staticType: int
      element: dart:core::@class::num::@method::<
      staticInvokeType: bool Function(num)
      staticType: bool
    rightSeparator: ;
    updaters
      PrefixExpression
        operator: ++
        operand: SimpleIdentifier
          token: i2
          element: i2@27
          staticType: null
        readElement: i2@27
        readType: int
        writeElement: i2@27
        writeType: int
        element: dart:core::@class::num::@method::+
        staticType: int
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_scope_variables_visibleInNextVariableInitializer() async {
    await assertNoErrorsInCode(r'''
void f() {
  for (var i = 0, j = i; j < 1; j++) {}
}
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithDeclarations
    variables: VariableDeclarationList
      keyword: var
      variables
        VariableDeclaration
          name: i
          equals: =
          initializer: IntegerLiteral
            literal: 0
            staticType: int
          declaredFragment: isPublic i@22
            element: hasImplicitType isPublic
              type: int
        VariableDeclaration
          name: j
          equals: =
          initializer: SimpleIdentifier
            token: i
            element: i@22
            staticType: int
          declaredFragment: isPublic j@29
            element: hasImplicitType isPublic
              type: int
    leftSeparator: ;
    condition: BinaryExpression
      leftOperand: SimpleIdentifier
        token: j
        element: j@29
        staticType: int
      operator: <
      rightOperand: IntegerLiteral
        literal: 1
        correspondingParameter: dart:core::@class::num::@method::<::@formalParameter::other
        staticType: int
      element: dart:core::@class::num::@method::<
      staticInvokeType: bool Function(num)
      staticType: bool
    rightSeparator: ;
    updaters
      PostfixExpression
        operand: SimpleIdentifier
          token: j
          element: j@29
          staticType: null
        operator: ++
        readElement: j@29
        readType: int
        writeElement: j@29
        writeType: int
        element: dart:core::@class::num::@method::+
        staticType: int
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }
}

@reflectiveTest
class ForStatementResolutionTest_ForPartsWithExpression
    extends PubPackageResolutionTest {
  test_condition_rewrite() async {
    await assertNoErrorsInCode(r'''
void f(bool Function() b) {
  for (; b(); ) {}
}
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithExpression
    leftSeparator: ;
    condition: FunctionExpressionInvocation
      function: SimpleIdentifier
        token: b
        element: <testLibrary>::@function::f::@formalParameter::b
        staticType: bool Function()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      element: <null>
      staticInvokeType: bool Function()
      staticType: bool
    rightSeparator: ;
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_initialization_patternAssignment() async {
    await assertNoErrorsInCode(r'''
void f() {
  int a;
  for ((a) = 0;;) {
    a;
  }
}
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithExpression
    initialization: PatternAssignment
      pattern: ParenthesizedPattern
        leftParenthesis: (
        pattern: AssignedVariablePattern
          name: a
          element: a@17
          matchedValueType: int
        rightParenthesis: )
        matchedValueType: int
      equals: =
      expression: IntegerLiteral
        literal: 0
        staticType: int
      patternTypeSchema: int
      staticType: int
    leftSeparator: ;
    rightSeparator: ;
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@17
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_scope_body_shadows_outer() async {
    await assertNoErrorsInCode(r'''
void f() {
  var i = 0;
  for (; i < 10; i++) {
    var i = 'a';
    i;
  }
}
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithExpression
    leftSeparator: ;
    condition: BinaryExpression
      leftOperand: SimpleIdentifier
        token: i
        element: i@17
        staticType: int
      operator: <
      rightOperand: IntegerLiteral
        literal: 10
        correspondingParameter: dart:core::@class::num::@method::<::@formalParameter::other
        staticType: int
      element: dart:core::@class::num::@method::<
      staticInvokeType: bool Function(num)
      staticType: bool
    rightSeparator: ;
    updaters
      PostfixExpression
        operand: SimpleIdentifier
          token: i
          element: i@17
          staticType: null
        operator: ++
        readElement: i@17
        readType: int
        writeElement: i@17
        writeType: int
        element: dart:core::@class::num::@method::+
        staticType: int
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      VariableDeclarationStatement
        variables: VariableDeclarationList
          keyword: var
          variables
            VariableDeclaration
              name: i
              equals: =
              initializer: SimpleStringLiteral
                literal: 'a'
              declaredFragment: isPublic i@56
                element: hasImplicitType isPublic
                  type: String
        semicolon: ;
      ExpressionStatement
        expression: SimpleIdentifier
          token: i
          element: i@56
          staticType: String
        semicolon: ;
    rightBracket: }
''');
  }

  test_update_super() async {
    await assertErrorsInCode(
      r'''
class A {
  void f() {
    for (;; super) {}
  }
}
''',
      [error(diag.missingAssignableSelector, 35, 5)],
    );

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithExpression
    leftSeparator: ;
    rightSeparator: ;
    updaters
      SuperExpression
        superKeyword: super
        staticType: A
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }
}

@reflectiveTest
class ForStatementResolutionTest_ForPartsWithPattern
    extends PubPackageResolutionTest {
  test_scope_afterLoop_uses_outer_despite_patternVariable() async {
    await assertNoErrorsInCode(r'''
void f((int, bool) x, int a) {
  for (var (a, b) = x; b; a--) {}
  a;
}
''');

    var node = findNode.singleBlockFunctionBody;
    assertResolvedNodeText(node, r'''
BlockFunctionBody
  block: Block
    leftBracket: {
    statements
      ForStatement
        forKeyword: for
        leftParenthesis: (
        forLoopParts: ForPartsWithPattern
          variables: PatternVariableDeclaration
            keyword: var
            pattern: RecordPattern
              leftParenthesis: (
              fields
                PatternField
                  pattern: DeclaredVariablePattern
                    name: a
                    declaredFragment: isPublic a@43
                      element: hasImplicitType isPublic
                        type: int
                    matchedValueType: int
                  element: <null>
                PatternField
                  pattern: DeclaredVariablePattern
                    name: b
                    declaredFragment: isPublic b@46
                      element: hasImplicitType isPublic
                        type: bool
                    matchedValueType: bool
                  element: <null>
              rightParenthesis: )
              matchedValueType: (int, bool)
            equals: =
            expression: SimpleIdentifier
              token: x
              element: <testLibrary>::@function::f::@formalParameter::x
              staticType: (int, bool)
            patternTypeSchema: (_, _)
          leftSeparator: ;
          condition: SimpleIdentifier
            token: b
            element: b@46
            staticType: bool
          rightSeparator: ;
          updaters
            PostfixExpression
              operand: SimpleIdentifier
                token: a
                element: a@43
                staticType: null
              operator: --
              readElement: a@43
              readType: int
              writeElement: a@43
              writeType: int
              element: dart:core::@class::num::@method::-
              staticType: int
        rightParenthesis: )
        body: Block
          leftBracket: {
          rightBracket: }
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: <testLibrary>::@function::f::@formalParameter::a
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_scope_body_shadows_patternVariable() async {
    await assertNoErrorsInCode(r'''
void f((int, bool) i) {
  for (var (a, b) = i; b; a--) {
    var a = 'a';
    a;
  }
}
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithPattern
    variables: PatternVariableDeclaration
      keyword: var
      pattern: RecordPattern
        leftParenthesis: (
        fields
          PatternField
            pattern: DeclaredVariablePattern
              name: a
              declaredFragment: isPublic a@36
                element: hasImplicitType isPublic
                  type: int
              matchedValueType: int
            element: <null>
          PatternField
            pattern: DeclaredVariablePattern
              name: b
              declaredFragment: isPublic b@39
                element: hasImplicitType isPublic
                  type: bool
              matchedValueType: bool
            element: <null>
        rightParenthesis: )
        matchedValueType: (int, bool)
      equals: =
      expression: SimpleIdentifier
        token: i
        element: <testLibrary>::@function::f::@formalParameter::i
        staticType: (int, bool)
      patternTypeSchema: (_, _)
    leftSeparator: ;
    condition: SimpleIdentifier
      token: b
      element: b@39
      staticType: bool
    rightSeparator: ;
    updaters
      PostfixExpression
        operand: SimpleIdentifier
          token: a
          element: a@36
          staticType: null
        operator: --
        readElement: a@36
        readType: int
        writeElement: a@36
        writeType: int
        element: dart:core::@class::num::@method::-
        staticType: int
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      VariableDeclarationStatement
        variables: VariableDeclarationList
          keyword: var
          variables
            VariableDeclaration
              name: a
              equals: =
              initializer: SimpleStringLiteral
                literal: 'a'
              declaredFragment: isPublic a@65
                element: hasImplicitType isPublic
                  type: String
        semicolon: ;
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@65
          staticType: String
        semicolon: ;
    rightBracket: }
''');
  }

  test_scope_body_uses_outer() async {
    await assertNoErrorsInCode(r'''
void f((int, bool) x) {
  for (var (a, b) = x; b; a--) {
    x;
  }
}
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithPattern
    variables: PatternVariableDeclaration
      keyword: var
      pattern: RecordPattern
        leftParenthesis: (
        fields
          PatternField
            pattern: DeclaredVariablePattern
              name: a
              declaredFragment: isPublic a@36
                element: hasImplicitType isPublic
                  type: int
              matchedValueType: int
            element: <null>
          PatternField
            pattern: DeclaredVariablePattern
              name: b
              declaredFragment: isPublic b@39
                element: hasImplicitType isPublic
                  type: bool
              matchedValueType: bool
            element: <null>
        rightParenthesis: )
        matchedValueType: (int, bool)
      equals: =
      expression: SimpleIdentifier
        token: x
        element: <testLibrary>::@function::f::@formalParameter::x
        staticType: (int, bool)
      patternTypeSchema: (_, _)
    leftSeparator: ;
    condition: SimpleIdentifier
      token: b
      element: b@39
      staticType: bool
    rightSeparator: ;
    updaters
      PostfixExpression
        operand: SimpleIdentifier
          token: a
          element: a@36
          staticType: null
        operator: --
        readElement: a@36
        readType: int
        writeElement: a@36
        writeType: int
        element: dart:core::@class::num::@method::-
        staticType: int
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: x
          element: <testLibrary>::@function::f::@formalParameter::x
          staticType: (int, bool)
        semicolon: ;
    rightBracket: }
''');
  }

  test_scope_patternVariables() async {
    await assertNoErrorsInCode(r'''
void f((int, bool) x) {
  for (var (a, b) = x; b; a--) {
    a;
    b;
  }
}
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithPattern
    variables: PatternVariableDeclaration
      keyword: var
      pattern: RecordPattern
        leftParenthesis: (
        fields
          PatternField
            pattern: DeclaredVariablePattern
              name: a
              declaredFragment: isPublic a@36
                element: hasImplicitType isPublic
                  type: int
              matchedValueType: int
            element: <null>
          PatternField
            pattern: DeclaredVariablePattern
              name: b
              declaredFragment: isPublic b@39
                element: hasImplicitType isPublic
                  type: bool
              matchedValueType: bool
            element: <null>
        rightParenthesis: )
        matchedValueType: (int, bool)
      equals: =
      expression: SimpleIdentifier
        token: x
        element: <testLibrary>::@function::f::@formalParameter::x
        staticType: (int, bool)
      patternTypeSchema: (_, _)
    leftSeparator: ;
    condition: SimpleIdentifier
      token: b
      element: b@39
      staticType: bool
    rightSeparator: ;
    updaters
      PostfixExpression
        operand: SimpleIdentifier
          token: a
          element: a@36
          staticType: null
        operator: --
        readElement: a@36
        readType: int
        writeElement: a@36
        writeType: int
        element: dart:core::@class::num::@method::-
        staticType: int
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          element: a@36
          staticType: int
        semicolon: ;
      ExpressionStatement
        expression: SimpleIdentifier
          token: b
          element: b@39
          staticType: bool
        semicolon: ;
    rightBracket: }
''');
  }

  test_scope_patternVariables_shadows_outer_in_expression() async {
    await assertNoErrorsInCode(r'''
void f((int, bool) a) {
  for (var (a, b) = a; b; a--) {}
}
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithPattern
    variables: PatternVariableDeclaration
      keyword: var
      pattern: RecordPattern
        leftParenthesis: (
        fields
          PatternField
            pattern: DeclaredVariablePattern
              name: a
              declaredFragment: isPublic a@36
                element: hasImplicitType isPublic
                  type: InvalidType
              matchedValueType: InvalidType
            element: <null>
          PatternField
            pattern: DeclaredVariablePattern
              name: b
              declaredFragment: isPublic b@39
                element: hasImplicitType isPublic
                  type: InvalidType
              matchedValueType: InvalidType
            element: <null>
        rightParenthesis: )
        matchedValueType: InvalidType
      equals: =
      expression: SimpleIdentifier
        token: a
        element: a@36
        staticType: InvalidType
      patternTypeSchema: (_, _)
    leftSeparator: ;
    condition: SimpleIdentifier
      token: b
      element: b@39
      staticType: InvalidType
    rightSeparator: ;
    updaters
      PostfixExpression
        operand: SimpleIdentifier
          token: a
          element: a@36
          staticType: null
        operator: --
        readElement: a@36
        readType: InvalidType
        writeElement: a@36
        writeType: InvalidType
        element: <null>
        staticType: InvalidType
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_scope_variables_uses_outer() async {
    await assertNoErrorsInCode(r'''
void f((int, bool) a) {
  for (var (a2, b) = a; b; a2--) {}
}
''');

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithPattern
    variables: PatternVariableDeclaration
      keyword: var
      pattern: RecordPattern
        leftParenthesis: (
        fields
          PatternField
            pattern: DeclaredVariablePattern
              name: a2
              declaredFragment: isPublic a2@36
                element: hasImplicitType isPublic
                  type: int
              matchedValueType: int
            element: <null>
          PatternField
            pattern: DeclaredVariablePattern
              name: b
              declaredFragment: isPublic b@40
                element: hasImplicitType isPublic
                  type: bool
              matchedValueType: bool
            element: <null>
        rightParenthesis: )
        matchedValueType: (int, bool)
      equals: =
      expression: SimpleIdentifier
        token: a
        element: <testLibrary>::@function::f::@formalParameter::a
        staticType: (int, bool)
      patternTypeSchema: (_, _)
    leftSeparator: ;
    condition: SimpleIdentifier
      token: b
      element: b@40
      staticType: bool
    rightSeparator: ;
    updaters
      PostfixExpression
        operand: SimpleIdentifier
          token: a2
          element: a2@36
          staticType: null
        operator: --
        readElement: a2@36
        readType: int
        writeElement: a2@36
        writeType: int
        element: dart:core::@class::num::@method::-
        staticType: int
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }
}
