// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeclaredVariablePatternResolutionTest);
  });
}

@reflectiveTest
class DeclaredVariablePatternResolutionTest extends PubPackageResolutionTest {
  test_final_switchCase() async {
    await assertErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case final y:
      break;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 46, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: final
  name: y
  declaredElement: hasImplicitType isFinal y@46
    type: int
  matchedValueType: int
''');
  }

  test_final_typed_switchCase() async {
    await assertErrorsInCode(r'''
void f(x) {
  switch (x) {
    case final int y:
      break;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 46, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: final
  type: NamedType
    name: int
    element: dart:core::<fragment>::@class::int
    element2: dart:core::<fragment>::@class::int#element
    type: int
  name: y
  declaredElement: isFinal y@46
    type: int
  matchedValueType: dynamic
''');
  }

  test_patternVariableDeclaration_final_recordPattern_listPattern() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  final [a] = [0];
}
''');
    var node = findNode.singlePatternVariableDeclaration.pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    DeclaredVariablePattern
      name: a
      declaredElement: hasImplicitType isFinal a@54
        type: int
      matchedValueType: int
  rightBracket: ]
  matchedValueType: List<int>
  requiredType: List<int>
''');
  }

  test_patternVariableDeclaration_final_recordPattern_listPattern_restPattern() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  final [...a] = [0, 1, 2];
}
''');
    var node = findNode.singlePatternVariableDeclaration.pattern;
    assertResolvedNodeText(node, r'''
ListPattern
  leftBracket: [
  elements
    RestPatternElement
      operator: ...
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType isFinal a@57
          type: List<int>
        matchedValueType: List<int>
  rightBracket: ]
  matchedValueType: List<int>
  requiredType: List<int>
''');
  }

  test_patternVariableDeclaration_final_recordPattern_mapPattern_entry() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  final {0: a} = {0: 1};
}
''');
    var node = findNode.singlePatternVariableDeclaration.pattern;
    assertResolvedNodeText(node, r'''
MapPattern
  leftBracket: {
  elements
    MapPatternEntry
      key: IntegerLiteral
        literal: 0
        staticType: int
      separator: :
      value: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType isFinal a@57
          type: int
        matchedValueType: int
  rightBracket: }
  matchedValueType: Map<int, int>
  requiredType: Map<int, int>
''');
  }

  test_patternVariableDeclaration_final_recordPattern_objectPattern() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  final int(sign: a) = 0;
}
''');
    var node = findNode.singlePatternVariableDeclaration.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: int
    element: dart:core::<fragment>::@class::int
    element2: dart:core::<fragment>::@class::int#element
    type: int
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: sign
        colon: :
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType isFinal a@63
          type: int
        matchedValueType: int
      element: dart:core::<fragment>::@class::int::@getter::sign
      element2: dart:core::<fragment>::@class::int::@getter::sign#element
  rightParenthesis: )
  matchedValueType: int
''');
  }

  test_patternVariableDeclaration_final_recordPattern_parenthesizedPattern() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  final (a) = 0;
}
''');
    var node = findNode.singlePatternVariableDeclaration.pattern;
    assertResolvedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: DeclaredVariablePattern
    name: a
    declaredElement: hasImplicitType isFinal a@54
      type: int
    matchedValueType: int
  rightParenthesis: )
  matchedValueType: int
''');
  }

  test_patternVariableDeclaration_final_recordPattern_recordPattern() async {
    await assertNoErrorsInCode(r'''
void f() {
  // ignore:unused_local_variable
  final (a,) = (0,);
}
''');
    var node = findNode.singlePatternVariableDeclaration.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: DeclaredVariablePattern
        name: a
        declaredElement: hasImplicitType isFinal a@54
          type: int
        matchedValueType: int
      element: <null>
      element2: <null>
  rightParenthesis: )
  matchedValueType: (int,)
''');
  }

  test_typed_switchCase() async {
    await assertErrorsInCode(r'''
void f(x) {
  switch (x) {
    case int y:
      break;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 40, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  type: NamedType
    name: int
    element: dart:core::<fragment>::@class::int
    element2: dart:core::<fragment>::@class::int#element
    type: int
  name: y
  declaredElement: y@40
    type: int
  matchedValueType: dynamic
''');
  }

  test_var_demoteType() async {
    await assertErrorsInCode(r'''
void f<T>(T x) {
  if (x is int) {
    if (x case var y) {}
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 54, 1),
    ]);

    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredElement: hasImplicitType y@54
    type: T
  matchedValueType: T & int
''');
  }

  test_var_ifCase() async {
    await assertErrorsInCode(r'''
void f(int x) {
  if (x case var y) {}
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 33, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredElement: hasImplicitType y@33
    type: int
  matchedValueType: int
''');
  }

  test_var_nullOrEquivalent_neverQuestion() async {
    await assertErrorsInCode(r'''
void f(Never? x) {
  if (x case var y) {}
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 36, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredElement: hasImplicitType y@36
    type: dynamic
  matchedValueType: Never?
''');
  }

  test_var_nullOrEquivalent_nullNone() async {
    await assertErrorsInCode(r'''
void f(Null x) {
  if (x case var y) {}
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 34, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredElement: hasImplicitType y@34
    type: dynamic
  matchedValueType: Null
''');
  }

  test_var_switchCase() async {
    await assertErrorsInCode(r'''
void f(int x) {
  switch (x) {
    case var y:
      break;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 44, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredElement: hasImplicitType y@44
    type: int
  matchedValueType: int
''');
  }

  test_var_switchCase_cast() async {
    await assertErrorsInCode(r'''
void f(num x) {
  switch (x) {
    case var y as int:
      break;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 44, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
CastPattern
  pattern: DeclaredVariablePattern
    keyword: var
    name: y
    declaredElement: hasImplicitType y@44
      type: int
    matchedValueType: int
  asToken: as
  type: NamedType
    name: int
    element: dart:core::<fragment>::@class::int
    element2: dart:core::<fragment>::@class::int#element
    type: int
  matchedValueType: num
''');
  }
}
