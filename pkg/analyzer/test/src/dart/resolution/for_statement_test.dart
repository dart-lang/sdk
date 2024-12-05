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
        ForStatementResolutionTest_ForEachPartsWithDeclaration);
    defineReflectiveTests(
        ForStatementResolutionTest_ForEachPartsWithIdentifier);
    defineReflectiveTests(ForStatementResolutionTest_ForEachPartsWithPattern);
    defineReflectiveTests(
        ForStatementResolutionTest_ForEachPartsWithPattern_await);
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
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
      name: v
      declaredElement: v@56
        type: int
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: <testLibraryFragment>::@function::g
        element: <testLibraryFragment>::@function::g#element
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
    await assertErrorsInCode(r'''
void f(dynamic values) {
  for (var v in values) {}
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 36, 1),
    ]);

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: v
      declaredElement: hasImplicitType v@36
        type: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      staticElement: <testLibraryFragment>::@function::f::@parameter::values
      element: <testLibraryFragment>::@function::f::@parameter::values#element
      staticType: dynamic
  rightParenthesis: )
  body: Block
    leftBracket: {
    rightBracket: }
''');
  }

  test_iterable_missing() async {
    await assertErrorsInCode(r'''
void f() {
  for (var v in) {
    v;
  }
}
''', [
      error(ParserErrorCode.MISSING_IDENTIFIER, 26, 1),
    ]);

    var node = findNode.forStatement('for');
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: v
      declaredElement: hasImplicitType v@22
        type: InvalidType
    inKeyword: in
    iterable: SimpleIdentifier
      token: <empty> <synthetic>
      staticElement: <null>
      element: <null>
      staticType: InvalidType
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          staticElement: v@22
          element: v@22
          staticType: InvalidType
        semicolon: ;
    rightBracket: }
''');
  }

  test_iterable_super() async {
    await assertErrorsInCode(r'''
abstract class A implements Iterable<int> {
  void f() {
    for (var v in super) {}
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 70, 1),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 75, 5),
    ]);

    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithDeclaration
    loopVariable: DeclaredIdentifier
      keyword: var
      name: v
      declaredElement: hasImplicitType v@70
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
        element: dynamic@-1
        element2: dynamic@-1
        type: dynamic
      name: v
      declaredElement: v@42
        type: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      staticElement: <testLibraryFragment>::@function::f::@parameter::values
      element: <testLibraryFragment>::@function::f::@parameter::values#element
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          staticElement: v@42
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
      declaredElement: hasImplicitType v@56
        type: Object?
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: <testLibraryFragment>::@function::g
        element: <testLibraryFragment>::@function::g#element
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
      declaredElement: hasImplicitType v@42
        type: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      staticElement: <testLibraryFragment>::@function::f::@parameter::values
      element: <testLibraryFragment>::@function::f::@parameter::values#element
      staticType: Iterable<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          staticElement: v@42
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
      declaredElement: hasImplicitType v@38
        type: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      staticElement: <testLibraryFragment>::@function::f::@parameter::values
      element: <testLibraryFragment>::@function::f::@parameter::values#element
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          staticElement: v@38
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
      declaredElement: hasImplicitType v@52
        type: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      staticElement: <testLibraryFragment>::@function::f::@parameter::values
      element: <testLibraryFragment>::@function::f::@parameter::values#element
      staticType: Stream<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          staticElement: v@52
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
      declaredElement: hasImplicitType x@39
        type: int
    inKeyword: in
    iterable: PrefixedIdentifier
      prefix: SimpleIdentifier
        token: x
        staticElement: <testLibraryFragment>::@function::f::@parameter::x
        element: <testLibraryFragment>::@function::f::@parameter::x#element
        staticType: List<List<int>>
      period: .
      identifier: SimpleIdentifier
        token: first
        staticElement: GetterMember
          base: dart:core::<fragment>::@class::Iterable::@getter::first
          substitution: {E: List<int>, E: List<int>}
        element: dart:core::<fragment>::@class::Iterable::@getter::first#element
        staticType: List<int>
      staticElement: GetterMember
        base: dart:core::<fragment>::@class::Iterable::@getter::first
        substitution: {E: List<int>, E: List<int>}
      element: dart:core::<fragment>::@class::Iterable::@getter::first#element
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: x
          staticElement: x@39
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
      staticElement: <testLibraryFragment>::@function::f::@parameter::v
      element: <testLibraryFragment>::@function::f::@parameter::v#element
      staticType: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: values
      staticElement: <testLibraryFragment>::@function::f::@parameter::values
      element: <testLibraryFragment>::@function::f::@parameter::values#element
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: v
          staticElement: <testLibraryFragment>::@function::f::@parameter::v
          element: <testLibraryFragment>::@function::f::@parameter::v#element
          staticType: dynamic
        semicolon: ;
    rightBracket: }
''');
  }

  test_iterable_super() async {
    await assertErrorsInCode(r'''
abstract class A implements Iterable<int> {
  void f(var v) {
    for (v in super) {}
  }
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 76, 5),
    ]);
    var node = findNode.singleForStatement;
    assertResolvedNodeText(node, r'''
ForStatement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithIdentifier
    identifier: SimpleIdentifier
      token: v
      staticElement: <testLibraryFragment>::@class::A::@method::f::@parameter::v
      element: <testLibraryFragment>::@class::A::@method::f::@parameter::v#element
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
        declaredElement: hasImplicitType a@24
          type: dynamic
        matchedValueType: dynamic
      rightParenthesis: )
      matchedValueType: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: dynamic
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@24
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
        declaredElement: hasImplicitType a@34
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@34
          element: a@34
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_iterable_Object() async {
    await assertErrorsInCode(r'''
void f(Object x) {
  for (var (a) in x) {
    a;
  }
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE, 37, 1),
    ]);
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
        declaredElement: hasImplicitType a@31
          type: InvalidType
        matchedValueType: InvalidType
      rightParenthesis: )
      matchedValueType: InvalidType
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: Object
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@31
          element: a@31
          staticType: InvalidType
        semicolon: ;
    rightBracket: }
''');
  }

  test_iterable_super() async {
    await assertErrorsInCode(r'''
abstract class A implements Iterable<int> {
  void f() {
    for (var (a) in super) {}
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 71, 1),
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 77, 5),
    ]);
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
        declaredElement: hasImplicitType a@71
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
    await assertErrorsInCode(r'''
void f() {
  for (var (int a) in g()) {}
}

T g<T>() => throw 0;
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 27, 1),
    ]);
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
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
        name: a
        declaredElement: a@27
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: <testLibraryFragment>::@function::g
        element: <testLibraryFragment>::@function::g#element
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
    await assertErrorsInCode(r'''
void f() {
  for (var (a) in g()) {}
}

T g<T>() => throw 0;
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 23, 1),
    ]);
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
        declaredElement: hasImplicitType a@23
          type: Object?
        matchedValueType: Object?
      rightParenthesis: )
      matchedValueType: Object?
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: <testLibraryFragment>::@function::g
        element: <testLibraryFragment>::@function::g#element
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
        declaredElement: hasImplicitType isFinal a@36
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@36
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
          element: dart:core::<fragment>::@class::num
          element2: dart:core::<fragment>::@class::num#element
          type: num
        name: a
        declaredElement: a@38
          type: num
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: List<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@38
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
        declaredElement: hasImplicitType a@36
          type: dynamic
        matchedValueType: dynamic
      rightParenthesis: )
      matchedValueType: dynamic
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: dynamic
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@36
          element: a@36
          staticType: dynamic
        semicolon: ;
    rightBracket: }
''');
  }

  test_iterable_Object() async {
    await assertErrorsInCode(r'''
void f(Object x) async {
  await for (var (a) in x) {
    a;
  }
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE, 49, 1),
    ]);
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
        declaredElement: hasImplicitType a@43
          type: InvalidType
        matchedValueType: InvalidType
      rightParenthesis: )
      matchedValueType: InvalidType
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: Object
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@43
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
        declaredElement: hasImplicitType a@48
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: Stream<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@48
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
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
        name: a
        declaredElement: a@39
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: <testLibraryFragment>::@function::g
        element: <testLibraryFragment>::@function::g#element
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
          staticElement: a@39
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
        declaredElement: hasImplicitType a@35
          type: Object?
        matchedValueType: Object?
      rightParenthesis: )
      matchedValueType: Object?
    inKeyword: in
    iterable: MethodInvocation
      methodName: SimpleIdentifier
        token: g
        staticElement: <testLibraryFragment>::@function::g
        element: <testLibraryFragment>::@function::g#element
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
          staticElement: a@35
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
        declaredElement: hasImplicitType isFinal a@50
          type: int
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: Stream<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@50
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
          element: dart:core::<fragment>::@class::num
          element2: dart:core::<fragment>::@class::num#element
          type: num
        name: a
        declaredElement: a@52
          type: num
        matchedValueType: int
      rightParenthesis: )
      matchedValueType: int
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: <testLibraryFragment>::@function::f::@parameter::x
      element: <testLibraryFragment>::@function::f::@parameter::x#element
      staticType: Stream<int>
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@52
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
        staticElement: <testLibraryFragment>::@function::f::@parameter::b
        element: <testLibraryFragment>::@function::f::@parameter::b#element
        staticType: bool Function()
      argumentList: ArgumentList
        leftParenthesis: (
        rightParenthesis: )
      staticElement: <null>
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
          staticElement: a@17
          element: a@17
          staticType: int
        semicolon: ;
    rightBracket: }
''');
  }

  test_update_super() async {
    await assertErrorsInCode(r'''
class A {
  void f() {
    for (;; super) {}
  }
}
''', [
      error(ParserErrorCode.MISSING_ASSIGNABLE_SELECTOR, 35, 5),
    ]);

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
              declaredElement: hasImplicitType a@36
                type: int
              matchedValueType: int
            element: <null>
            element2: <null>
          PatternField
            pattern: DeclaredVariablePattern
              name: b
              declaredElement: hasImplicitType b@39
                type: bool
              matchedValueType: bool
            element: <null>
            element2: <null>
        rightParenthesis: )
        matchedValueType: (int, bool)
      equals: =
      expression: SimpleIdentifier
        token: x
        staticElement: <testLibraryFragment>::@function::f::@parameter::x
        element: <testLibraryFragment>::@function::f::@parameter::x#element
        staticType: (int, bool)
      patternTypeSchema: (_, _)
    leftSeparator: ;
    condition: SimpleIdentifier
      token: b
      staticElement: b@39
      element: b@39
      staticType: bool
    rightSeparator: ;
    updaters
      PostfixExpression
        operand: SimpleIdentifier
          token: a
          staticElement: a@36
          element: a@36
          staticType: null
        operator: --
        readElement: a@36
        readElement2: a@36
        readType: int
        writeElement: a@36
        writeElement2: a@36
        writeType: int
        staticElement: dart:core::<fragment>::@class::num::@method::-
        element: dart:core::<fragment>::@class::num::@method::-#element
        staticType: int
  rightParenthesis: )
  body: Block
    leftBracket: {
    statements
      ExpressionStatement
        expression: SimpleIdentifier
          token: a
          staticElement: a@36
          element: a@36
          staticType: int
        semicolon: ;
      ExpressionStatement
        expression: SimpleIdentifier
          token: b
          staticElement: b@39
          element: b@39
          staticType: bool
        semicolon: ;
    rightBracket: }
''');
  }
}
