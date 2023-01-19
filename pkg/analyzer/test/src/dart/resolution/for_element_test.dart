// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/utilities/legacy.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ForElementResolutionTest_ForEachPartsWithDeclaration);
    defineReflectiveTests(ForElementResolutionTest_ForEachPartsWithPattern);
    defineReflectiveTests(ForElementResolutionTest_ForPartsWithDeclarations);
    defineReflectiveTests(ForElementResolutionTest_ForPartsWithPattern);
  });
}

@reflectiveTest
class ForElementResolutionTest_ForEachPartsWithDeclaration
    extends PubPackageResolutionTest with WithoutNullSafetyMixin {
  test_optIn_fromOptOut() async {
    noSoundNullSafety = false;
    newFile('$testPackageLibPath/a.dart', r'''
class A implements Iterable<int> {
  Iterator<int> iterator => throw 0;
}
''');

    await assertNoErrorsInCode(r'''
// @dart = 2.7
import 'a.dart';

f(A a) {
  for (var v in a) {
    v;
  }
}
''');
  }

  test_withDeclaration_scope() async {
    await assertNoErrorsInCode(r'''
main() {
  <int>[for (var i in [1, 2, 3]) i]; // 1
  <double>[for (var i in [1.1, 2.2, 3.3]) i]; // 2
}
''');

    assertElement(
      findNode.simple('i]; // 1'),
      findNode.declaredIdentifier('i in [1, 2').declaredElement!,
    );
    assertElement(
      findNode.simple('i]; // 2'),
      findNode.declaredIdentifier('i in [1.1').declaredElement!,
    );
  }

  test_withIdentifier_topLevelVariable() async {
    await assertNoErrorsInCode(r'''
int v = 0;
main() {
  <int>[for (v in [1, 2, 3]) v];
}
''');
    assertElement(
      findNode.simple('v];'),
      findElement.topGet('v'),
    );
  }
}

@reflectiveTest
class ForElementResolutionTest_ForEachPartsWithPattern
    extends PubPackageResolutionTest {
  test_iterable_dynamic() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  [for (var (a) in x) a];
}
''');
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@25
          type: dynamic
      rightParenthesis: )
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: dynamic
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    staticElement: a@25
    staticType: dynamic
''');
  }

  test_iterable_List() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  [for (var (a) in x) a];
}
''');
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@35
          type: int
      rightParenthesis: )
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: List<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    staticElement: a@35
    staticType: int
''');
  }

  test_iterable_Object() async {
    await assertErrorsInCode(r'''
void f(Object x) {
  [for (var (a) in x) a];
}
''', [
      error(CompileTimeErrorCode.FOR_IN_OF_INVALID_TYPE, 38, 1),
    ]);
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType a@32
          type: dynamic
      rightParenthesis: )
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: Object
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    staticElement: a@32
    staticType: dynamic
''');
  }

  test_keyword_final_patternVariable() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  [for (final (a) in x) a];
}
''');
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: final
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType isFinal a@37
          type: int
      rightParenthesis: )
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: List<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    staticElement: a@37
    staticType: int
''');
  }

  test_pattern_patternVariable_typed() async {
    await assertNoErrorsInCode(r'''
void f(List<int> x) {
  [for (var (num a) in x) a];
}
''');
    var node = findNode.forElement('for');
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForEachPartsWithPattern
    keyword: var
    pattern: ParenthesizedPattern
      leftParenthesis: (
      pattern: DeclaredVariablePattern
        type: NamedType
          name: SimpleIdentifier
            token: num
            staticElement: dart:core::@class::num
            staticType: null
          type: num
        name: a
        declaredElement: a@39
          type: num
      rightParenthesis: )
    inKeyword: in
    iterable: SimpleIdentifier
      token: x
      staticElement: self::@function::f::@parameter::x
      staticType: List<int>
  rightParenthesis: )
  body: SimpleIdentifier
    token: a
    staticElement: a@39
    staticType: num
''');
  }
}

@reflectiveTest
class ForElementResolutionTest_ForPartsWithDeclarations
    extends PubPackageResolutionTest {
  test_condition_rewrite() async {
    await assertNoErrorsInCode(r'''
f(bool Function() b) {
  <int>[for (; b(); ) 0];
}
''');

    final node = findNode.functionExpressionInvocation('b()');
    assertResolvedNodeText(node, r'''
FunctionExpressionInvocation
  function: SimpleIdentifier
    token: b
    staticElement: self::@function::f::@parameter::b
    staticType: bool Function()
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticElement: <null>
  staticInvokeType: bool Function()
  staticType: bool
''');
  }

  test_declaredVariableScope() async {
    await assertNoErrorsInCode(r'''
main() {
  <int>[for (var i = 1; i < 10; i += 3) i]; // 1
  <double>[for (var i = 1.1; i < 10; i += 5) i]; // 2
}
''');

    assertElement(
      findNode.simple('i]; // 1'),
      findNode.variableDeclaration('i = 1;').declaredElement!,
    );
    assertElement(
      findNode.simple('i]; // 2'),
      findNode.variableDeclaration('i = 1.1;').declaredElement!,
    );
  }
}

@reflectiveTest
class ForElementResolutionTest_ForPartsWithPattern
    extends PubPackageResolutionTest {
  test_it() async {
    await assertNoErrorsInCode(r'''
void f((int, bool) x) {
  [for (var (a, b) = x; b; a--) 0];
}
''');

    final node = findNode.singleForElement;
    assertResolvedNodeText(node, r'''
ForElement
  forKeyword: for
  leftParenthesis: (
  forLoopParts: ForPartsWithPattern
    variables: PatternVariableDeclaration
      keyword: var
      pattern: RecordPattern
        leftParenthesis: (
        fields
          RecordPatternField
            pattern: DeclaredVariablePattern
              name: a
              declaredElement: hasImplicitType a@37
                type: int
            fieldElement: <null>
          RecordPatternField
            pattern: DeclaredVariablePattern
              name: b
              declaredElement: hasImplicitType b@40
                type: bool
            fieldElement: <null>
        rightParenthesis: )
      equals: =
      expression: SimpleIdentifier
        token: x
        staticElement: self::@function::f::@parameter::x
        staticType: (int, bool)
    leftSeparator: ;
    condition: SimpleIdentifier
      token: b
      staticElement: b@40
      staticType: bool
    rightSeparator: ;
    updaters
      PostfixExpression
        operand: SimpleIdentifier
          token: a
          staticElement: a@37
          staticType: null
        operator: --
        readElement: a@37
        readType: int
        writeElement: a@37
        writeType: int
        staticElement: dart:core::@class::num::@method::-
        staticType: int
  rightParenthesis: )
  body: IntegerLiteral
    literal: 0
    staticType: int
''');
  }
}
