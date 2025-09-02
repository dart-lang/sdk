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
    await assertErrorsInCode(
      r'''
void f(int x) {
  switch (x) {
    case final y:
      break;
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 46, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: final
  name: y
  declaredFragment: isFinal isPublic y@46
    element: hasImplicitType isFinal isPublic
      type: int
  matchedValueType: int
''');
  }

  test_final_typed_switchCase() async {
    await assertErrorsInCode(
      r'''
void f(x) {
  switch (x) {
    case final int y:
      break;
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 46, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: final
  type: NamedType
    name: int
    element2: dart:core::@class::int
    type: int
  name: y
  declaredFragment: isFinal isPublic y@46
    element: isFinal isPublic
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
      declaredFragment: isFinal isPublic a@54
        element: hasImplicitType isFinal isPublic
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
        declaredFragment: isFinal isPublic a@57
          element: hasImplicitType isFinal isPublic
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
        declaredFragment: isFinal isPublic a@57
          element: hasImplicitType isFinal isPublic
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
    element2: dart:core::@class::int
    type: int
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: sign
        colon: :
      pattern: DeclaredVariablePattern
        name: a
        declaredFragment: isFinal isPublic a@63
          element: hasImplicitType isFinal isPublic
            type: int
        matchedValueType: int
      element2: dart:core::@class::int::@getter::sign
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
    declaredFragment: isFinal isPublic a@54
      element: hasImplicitType isFinal isPublic
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
        declaredFragment: isFinal isPublic a@54
          element: hasImplicitType isFinal isPublic
            type: int
        matchedValueType: int
      element2: <null>
  rightParenthesis: )
  matchedValueType: (int,)
''');
  }

  test_typed_switchCase() async {
    await assertErrorsInCode(
      r'''
void f(x) {
  switch (x) {
    case int y:
      break;
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 40, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  type: NamedType
    name: int
    element2: dart:core::@class::int
    type: int
  name: y
  declaredFragment: isPublic y@40
    element: isPublic
      type: int
  matchedValueType: dynamic
''');
  }

  test_var_demoteType() async {
    await assertErrorsInCode(
      r'''
void f<T>(T x) {
  if (x is int) {
    if (x case var y) {}
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 54, 1)],
    );

    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredFragment: isPublic y@54
    element: hasImplicitType isPublic
      type: T
  matchedValueType: T & int
''');
  }

  test_var_ifCase() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  if (x case var y) {}
}
''',
      [error(WarningCode.unusedLocalVariable, 33, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredFragment: isPublic y@33
    element: hasImplicitType isPublic
      type: int
  matchedValueType: int
''');
  }

  test_var_nullOrEquivalent_neverQuestion() async {
    await assertErrorsInCode(
      r'''
void f(Never? x) {
  if (x case var y) {}
}
''',
      [error(WarningCode.unusedLocalVariable, 36, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredFragment: isPublic y@36
    element: hasImplicitType isPublic
      type: dynamic
  matchedValueType: Never?
''');
  }

  test_var_nullOrEquivalent_nullNone() async {
    await assertErrorsInCode(
      r'''
void f(Null x) {
  if (x case var y) {}
}
''',
      [error(WarningCode.unusedLocalVariable, 34, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredFragment: isPublic y@34
    element: hasImplicitType isPublic
      type: dynamic
  matchedValueType: Null
''');
  }

  test_var_switchCase() async {
    await assertErrorsInCode(
      r'''
void f(int x) {
  switch (x) {
    case var y:
      break;
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 44, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
DeclaredVariablePattern
  keyword: var
  name: y
  declaredFragment: isPublic y@44
    element: hasImplicitType isPublic
      type: int
  matchedValueType: int
''');
  }

  test_var_switchCase_cast() async {
    await assertErrorsInCode(
      r'''
void f(num x) {
  switch (x) {
    case var y as int:
      break;
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 44, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
CastPattern
  pattern: DeclaredVariablePattern
    keyword: var
    name: y
    declaredFragment: isPublic y@44
      element: hasImplicitType isPublic
        type: int
    matchedValueType: int
  asToken: as
  type: NamedType
    name: int
    element2: dart:core::@class::int
    type: int
  matchedValueType: num
''');
  }
}
