// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
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
    defineReflectiveTests(
      ForStatementResolutionTest_ForEachPartsWithPattern_await,
    );
    defineReflectiveTests(ForStatementResolutionTest_ForPartsWithExpression);
    defineReflectiveTests(ForStatementResolutionTest_ForPartsWithPattern);
  });
}

// TODO(scheglov): Move other for-in tests here.
@reflectiveTest
class ForStatementResolutionTest_ForEachPartsWithDeclaration
    extends PubPackageResolutionTest {
  test_iterable_contextType() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  for (int v in g()) {}
}

T g<T>() => throw 0;
''');

    var node = findNode.forStatement('for');
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      type: NamedType
        name: int
        element2: dart:core::@class::int
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

  test_iterable_dynamic() async {
    await assertErrorsInCode(
      r'''
void f(dynamic values) {
  for (var v in values) {}
}
''',
      [error(WarningCode.unusedLocalVariable, 36, 1)],
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

  test_iterable_missing() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (var v in) {
    v;
  }
}
''',
      [error(ParserErrorCode.missingIdentifier, 26, 1)],
    );

    var node = findNode.forStatement('for');
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

  test_iterable_super() async {
    await assertErrorsInCode(
      r'''
abstract class A implements Iterable<int> {
  void f() {
    for (var v in super) {}
  }
}
''',
      [
        error(WarningCode.unusedLocalVariable, 70, 1),
        error(ParserErrorCode.missingAssignableSelector, 75, 5),
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

  test_loopVariable_dynamic() async {
    await resolveTestCode(r'''
void f(List<int> values) {
  for (dynamic v in values) {
    v;
  }
}''');
    var node = findNode.forStatement('for');
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      type: NamedType
        name: dynamic
        element2: dynamic
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

  test_loopVariable_var_genericFunction() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  for (var v in g()) {}
}

T g<T>() => throw 0;
''');

    var node = findNode.forStatement('for');
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

  test_loopVariable_var_iterable() async {
    await resolveTestCode(r'''
void f(Iterable<int> values) {
  for (var v in values) {
    v;
  }
}
''');
    var node = findNode.forStatement('for');
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

  test_loopVariable_var_list() async {
    await resolveTestCode(r'''
void f(List<int> values) {
  for (var v in values) {
    v;
  }
}
''');
    var node = findNode.forStatement('for');
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

  test_loopVariable_var_stream() async {
    await resolveTestCode(r'''
void f(Stream<int> values) async {
  await for (var v in values) {
    v;
  }
}''');
    var node = findNode.forStatement('for');
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

  /// Test that the parameter `x` is in the scope of the iterable.
  /// But the declared identifier `x` is in the scope of the body.
  test_scope() async {
    await assertNoErrorsInCode('''
void f(List<List<int>> x) {
  for (var x in x.first) {
    x;
  }
}
''');
    var node = findNode.forStatement('for');
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: x
      declaredFragment: isPublic x@39
        element: hasImplicitType isPublic
          type: int
    inKeyword: in
    iterable: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: x
        element: <testLibrary>::@function::f::@formalParameter::x
        staticType: List<List<int>>
      period: .
      identifier: SimpleIdentifier
        token: first
        element: GetterMember
          baseElement: dart:core::@class::Iterable::@getter::first
          substitution: {E: List<int>}
        staticType: List<int>
      element: GetterMember
        baseElement: dart:core::@class::Iterable::@getter::first
        substitution: {E: List<int>}
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: x
          element: x@39
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_type_genericFunctionType() async {
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
  test_identifier_dynamic() async {
    await resolveTestCode(r'''
void f(var v, List<int> values) {
  for (v in values) {
    v;
  }
}
''');
    var node = findNode.forStatement('for');
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

  test_iterable_super() async {
    await assertErrorsInCode(
      r'''
abstract class A implements Iterable<int> {
  void f(var v) {
    for (v in super) {}
  }
}
''',
      [error(ParserErrorCode.missingAssignableSelector, 76, 5)],
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
}

@reflectiveTest
class ForStatementResolutionTest_ForEachPartsWithPattern
    extends PubPackageResolutionTest {
  test_iterable_dynamic() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  for (var (a) in x) {
    a;
  }
}
''');
    var node = findNode.forStatement('for');
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

  test_iterable_List() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  for (var (a) in x) {
    a;
  }
}
''');
    var node = findNode.forStatement('for');
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

  test_iterable_Object() async {
    await assertErrorsInCode(
      r'''
void f(Object x) {
  for (var (a) in x) {
    a;
  }
}
''',
      [error(CompileTimeErrorCode.forInOfInvalidType, 37, 1)],
    );
    var node = findNode.forStatement('for');
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

  test_iterable_super() async {
    await assertErrorsInCode(
      r'''
abstract class A implements Iterable<int> {
  void f() {
    for (var (a) in super) {}
  }
}
''',
      [
        error(WarningCode.unusedLocalVariable, 71, 1),
        error(ParserErrorCode.missingAssignableSelector, 77, 5),
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

  test_iterableContextType_patternVariable_typed() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (var (int a) in g()) {}
}

T g<T>() => throw 0;
''',
      [error(WarningCode.unusedLocalVariable, 27, 1)],
    );
    var node = findNode.forStatement('for');
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
          element2: dart:core::@class::int
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

  test_iterableContextType_patternVariable_untyped() async {
    await assertErrorsInCode(
      r'''
void f() {
  for (var (a) in g()) {}
}

T g<T>() => throw 0;
''',
      [error(WarningCode.unusedLocalVariable, 23, 1)],
    );
    var node = findNode.forStatement('for');
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

  test_keyword_final_patternVariable() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  for (final (a) in x) {
    a;
  }
}
''');
    var node = findNode.forStatement('for');
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

  test_pattern_patternVariable_typed() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  for (var (num a) in x) {
    a;
  }
}
''');
    var node = findNode.forStatement('for');
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
          element2: dart:core::@class::num
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
}

@reflectiveTest
class ForStatementResolutionTest_ForEachPartsWithPattern_await
    extends PubPackageResolutionTest {
  test_iterable_dynamic() async {
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

  test_iterable_Object() async {
    await assertErrorsInCode(
      r'''
void f(Object x) async {
  await for (var (a) in x) {
    a;
  }
}
''',
      [error(CompileTimeErrorCode.forInOfInvalidType, 49, 1)],
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

  test_iterable_Stream() async {
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

  test_iterableContextType_patternVariable_typed() async {
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
          element2: dart:core::@class::int
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

  test_iterableContextType_patternVariable_untyped() async {
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

  test_keyword_final_patternVariable() async {
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

  test_pattern_patternVariable_typed() async {
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
          element2: dart:core::@class::num
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
          element2: a@17
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

  test_update_super() async {
    await assertErrorsInCode(
      r'''
class A {
  void f() {
    for (;; super) {}
  }
}
''',
      [error(ParserErrorCode.missingAssignableSelector, 35, 5)],
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
  test_it() async {
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
            element2: <null>
          PatternField
            pattern: DeclaredVariablePattern
              name: b
              declaredFragment: isPublic b@39
                element: hasImplicitType isPublic
                  type: bool
              matchedValueType: bool
            element2: <null>
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
        readElement2: a@36
        readType: int
        writeElement2: a@36
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
}
