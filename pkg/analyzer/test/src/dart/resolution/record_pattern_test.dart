// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordPatternResolutionTest);
  });
}

@reflectiveTest
class RecordPatternResolutionTest extends PubPackageResolutionTest {
  test_dynamicType_empty() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case ():
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_dynamicType_named_variable_untyped() async {
    await assertErrorsInCode(
      r'''
void f(x) {
  switch (x) {
    case (foo: var y):
      break;
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 46, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredFragment: isPublic y@46
          element: hasImplicitType isPublic
            type: dynamic
        matchedValueType: dynamic
      element2: <null>
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_dynamicType_positional_variable_untyped() async {
    await assertErrorsInCode(
      r'''
void f(x) {
  switch (x) {
    case (var y,):
      break;
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 41, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredFragment: isPublic y@41
          element: hasImplicitType isPublic
            type: dynamic
        matchedValueType: dynamic
      element2: <null>
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_interfaceType_empty() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case ():
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_interfaceType_named_constant() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case (foo: 0):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
        matchedValueType: Object?
      element2: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_interfaceType_named_variable_typed() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  switch (x) {
    case (foo: int y):
      break;
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 54, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        type: NamedType
          name: int
          element2: dart:core::@class::int
          type: int
        name: y
        declaredFragment: isPublic y@54
          element: isPublic
            type: int
        matchedValueType: Object?
      element2: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_interfaceType_named_variable_untyped() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  switch (x) {
    case (foo: var y):
      break;
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 54, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredFragment: isPublic y@54
          element: hasImplicitType isPublic
            type: Object?
        matchedValueType: Object?
      element2: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_interfaceType_positional_constant() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case (0,):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
        matchedValueType: Object?
      element2: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_interfaceType_positional_variable_typed() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  switch (x) {
    case (int y,):
      break;
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 49, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: DeclaredVariablePattern
        type: NamedType
          name: int
          element2: dart:core::@class::int
          type: int
        name: y
        declaredFragment: isPublic y@49
          element: isPublic
            type: int
        matchedValueType: Object?
      element2: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_interfaceType_positional_variable_untyped() async {
    await assertErrorsInCode(
      r'''
void f(Object? x) {
  switch (x) {
    case (var y,):
      break;
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 49, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredFragment: isPublic y@49
          element: hasImplicitType isPublic
            type: Object?
        matchedValueType: Object?
      element2: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_recordType_differentShape_named_tooFew_hasName() async {
    await assertErrorsInCode(
      r'''
void f(() x) {
  switch (x) {
    case (a: var b):
      break;
    default:
  }
}
''',
      [
        error(WarningCode.patternNeverMatchesValueType, 39, 10),
        error(WarningCode.unusedLocalVariable, 47, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: a
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: b
        declaredFragment: isPublic b@47
          element: hasImplicitType isPublic
            type: Object?
        matchedValueType: Object?
      element2: <null>
  rightParenthesis: )
  matchedValueType: ()
''');
  }

  test_recordType_differentShape_named_tooFew_noName() async {
    await assertErrorsInCode(
      r'''
void f(() x) {
  switch (x) {
    case (: var a):
      break;
    default:
  }
}
''',
      [
        error(WarningCode.patternNeverMatchesValueType, 39, 9),
        error(WarningCode.unusedLocalVariable, 46, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: a
        declaredFragment: isPublic a@46
          element: hasImplicitType isPublic
            type: Object?
        matchedValueType: Object?
      element2: <null>
  rightParenthesis: )
  matchedValueType: ()
''');
  }

  test_recordType_differentShape_named_tooFew_noName2() async {
    await assertErrorsInCode(
      r'''
void f(({int b}) x) {
  switch (x) {
    case (: var a):
      break;
  }
}
''',
      [
        error(WarningCode.patternNeverMatchesValueType, 46, 9),
        error(WarningCode.unusedLocalVariable, 53, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: a
        declaredFragment: isPublic a@53
          element: hasImplicitType isPublic
            type: Object?
        matchedValueType: Object?
      element2: <null>
  rightParenthesis: )
  matchedValueType: ({int b})
''');
  }

  test_recordType_differentShape_named_tooMany_noName() async {
    await assertErrorsInCode(
      r'''
void f(({int a, int b}) x) {
  switch (x) {
    case (: var a):
      break;
  }
}
''',
      [
        error(WarningCode.patternNeverMatchesValueType, 53, 9),
        error(WarningCode.unusedLocalVariable, 60, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: a
        declaredFragment: isPublic a@60
          element: hasImplicitType isPublic
            type: Object?
        matchedValueType: Object?
      element2: <null>
  rightParenthesis: )
  matchedValueType: ({int a, int b})
''');
  }

  test_recordType_differentShape_positional_tooFew() async {
    await assertErrorsInCode(
      r'''
void f(() x) {
  switch (x) {
    case (var a,):
      break;
    default:
  }
}
''',
      [
        error(WarningCode.patternNeverMatchesValueType, 39, 8),
        error(WarningCode.unusedLocalVariable, 44, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: DeclaredVariablePattern
        keyword: var
        name: a
        declaredFragment: isPublic a@44
          element: hasImplicitType isPublic
            type: Object?
        matchedValueType: Object?
      element2: <null>
  rightParenthesis: )
  matchedValueType: ()
''');
  }

  test_recordType_differentShape_positional_tooMany() async {
    await assertErrorsInCode(
      r'''
void f((int, String) x) {
  switch (x) {
    case (var a,):
      break;
  }
}
''',
      [
        error(WarningCode.patternNeverMatchesValueType, 50, 8),
        error(WarningCode.unusedLocalVariable, 55, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: DeclaredVariablePattern
        keyword: var
        name: a
        declaredFragment: isPublic a@55
          element: hasImplicitType isPublic
            type: Object?
        matchedValueType: Object?
      element2: <null>
  rightParenthesis: )
  matchedValueType: (int, String)
''');
  }

  test_recordType_sameShape_empty() async {
    await assertErrorsInCode(
      r'''
void f(() x) {
  switch (x) {
    case ():
      break;
    default:
  }
}
''',
      [
        error(WarningCode.deadCode, 60, 7),
        error(WarningCode.unreachableSwitchDefault, 60, 7),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  rightParenthesis: )
  matchedValueType: ()
''');
  }

  test_recordType_sameShape_mixed() async {
    await assertErrorsInCode(
      r'''
void f((int, double, {String foo}) x) {
  switch (x) {
    case (var a, foo: var b, var c):
      break;
  }
}
''',
      [
        error(WarningCode.unusedLocalVariable, 69, 1),
        error(WarningCode.unusedLocalVariable, 81, 1),
        error(WarningCode.unusedLocalVariable, 88, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: DeclaredVariablePattern
        keyword: var
        name: a
        declaredFragment: isPublic a@69
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      element2: <null>
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: b
        declaredFragment: isPublic b@81
          element: hasImplicitType isPublic
            type: String
        matchedValueType: String
      element2: <null>
    PatternField
      pattern: DeclaredVariablePattern
        keyword: var
        name: c
        declaredFragment: isPublic c@88
          element: hasImplicitType isPublic
            type: double
        matchedValueType: double
      element2: <null>
  rightParenthesis: )
  matchedValueType: (int, double, {String foo})
''');
  }

  test_recordType_sameShape_named_hasName_unresolved() async {
    await assertErrorsInCode(
      r'''
void f(({int foo}) x) {
  switch (x) {
    case (bar: var a):
      break;
  }
}
''',
      [
        error(WarningCode.patternNeverMatchesValueType, 48, 12),
        error(WarningCode.unusedLocalVariable, 58, 1),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: bar
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: a
        declaredFragment: isPublic a@58
          element: hasImplicitType isPublic
            type: Object?
        matchedValueType: Object?
      element2: <null>
  rightParenthesis: )
  matchedValueType: ({int foo})
''');
  }

  test_recordType_sameShape_named_hasName_variable() async {
    await assertErrorsInCode(
      r'''
void f(({int foo}) x) {
  switch (x) {
    case (foo: var y):
      break;
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 58, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredFragment: isPublic y@58
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      element2: <null>
  rightParenthesis: )
  matchedValueType: ({int foo})
''');
  }

  test_recordType_sameShape_named_noName_constant() async {
    await assertErrorsInCode(
      r'''
void f(({int foo}) x) {
  switch (x) {
    case (: 0):
      break;
  }
}
''',
      [
        error(WarningCode.patternNeverMatchesValueType, 48, 5),
        error(CompileTimeErrorCode.missingNamedPatternFieldName, 49, 3),
      ],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
        matchedValueType: Object?
      element2: <null>
  rightParenthesis: )
  matchedValueType: ({int foo})
''');
  }

  test_recordType_sameShape_named_noName_variable() async {
    await assertErrorsInCode(
      r'''
void f(({int foo}) x) {
  switch (x) {
    case (: var foo):
      break;
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 55, 3)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: foo
        declaredFragment: isPublic foo@55
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      element2: <null>
  rightParenthesis: )
  matchedValueType: ({int foo})
''');
  }

  test_recordType_sameShape_named_noName_variable_cast() async {
    await assertErrorsInCode(
      r'''
void f(({int? foo}) x) {
  switch (x) {
    case (: var foo as int):
      break;
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 56, 3)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: CastPattern
        pattern: DeclaredVariablePattern
          keyword: var
          name: foo
          declaredFragment: isPublic foo@56
            element: hasImplicitType isPublic
              type: int
          matchedValueType: int
        asToken: as
        type: NamedType
          name: int
          element2: dart:core::@class::int
          type: int
        matchedValueType: int?
      element2: <null>
  rightParenthesis: )
  matchedValueType: ({int? foo})
''');
  }

  test_recordType_sameShape_named_noName_variable_nullAssert() async {
    await assertErrorsInCode(
      r'''
void f(({int? foo}) x) {
  switch (x) {
    case (: var foo!):
      break;
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 56, 3)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: NullAssertPattern
        pattern: DeclaredVariablePattern
          keyword: var
          name: foo
          declaredFragment: isPublic foo@56
            element: hasImplicitType isPublic
              type: int
          matchedValueType: int
        operator: !
        matchedValueType: int?
      element2: <null>
  rightParenthesis: )
  matchedValueType: ({int? foo})
''');
  }

  test_recordType_sameShape_named_noName_variable_nullCheck() async {
    await assertErrorsInCode(
      r'''
void f(({int? foo}) x) {
  switch (x) {
    case (: var foo?):
      break;
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 56, 3)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: NullCheckPattern
        pattern: DeclaredVariablePattern
          keyword: var
          name: foo
          declaredFragment: isPublic foo@56
            element: hasImplicitType isPublic
              type: int
          matchedValueType: int
        operator: ?
        matchedValueType: int?
      element2: <null>
  rightParenthesis: )
  matchedValueType: ({int? foo})
''');
  }

  test_recordType_sameShape_positional_variable() async {
    await assertErrorsInCode(
      r'''
void f((int,) x) {
  switch (x) {
    case (var a,):
      break;
  }
}
''',
      [error(WarningCode.unusedLocalVariable, 48, 1)],
    );
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: DeclaredVariablePattern
        keyword: var
        name: a
        declaredFragment: isPublic a@48
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      element2: <null>
  rightParenthesis: )
  matchedValueType: (int,)
''');
  }

  test_variableDeclaration_inferredType() async {
    await assertErrorsInCode(
      r'''
void f((int, String) x) {
  var (a, b) = x;
}
''',
      [
        error(WarningCode.unusedLocalVariable, 33, 1),
        error(WarningCode.unusedLocalVariable, 36, 1),
      ],
    );
    var node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: RecordPattern
    leftParenthesis: (
    fields
      PatternField
        pattern: DeclaredVariablePattern
          name: a
          declaredFragment: isPublic a@33
            element: hasImplicitType isPublic
              type: int
          matchedValueType: int
        element2: <null>
      PatternField
        pattern: DeclaredVariablePattern
          name: b
          declaredFragment: isPublic b@36
            element: hasImplicitType isPublic
              type: String
          matchedValueType: String
        element2: <null>
    rightParenthesis: )
    matchedValueType: (int, String)
  equals: =
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: (int, String)
  patternTypeSchema: (_, _)
''');
  }

  test_variableDeclaration_typeSchema() async {
    await assertErrorsInCode(
      r'''
void f() {
  var (int a, String b) = g();
}

(T, U) g<T, U>() => throw 0;
''',
      [
        error(WarningCode.unusedLocalVariable, 22, 1),
        error(WarningCode.unusedLocalVariable, 32, 1),
      ],
    );
    var node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: RecordPattern
    leftParenthesis: (
    fields
      PatternField
        pattern: DeclaredVariablePattern
          type: NamedType
            name: int
            element2: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@22
            element: isPublic
              type: int
          matchedValueType: int
        element2: <null>
      PatternField
        pattern: DeclaredVariablePattern
          type: NamedType
            name: String
            element2: dart:core::@class::String
            type: String
          name: b
          declaredFragment: isPublic b@32
            element: isPublic
              type: String
          matchedValueType: String
        element2: <null>
    rightParenthesis: )
    matchedValueType: (int, String)
  equals: =
  expression: MethodInvocation
    methodName: SimpleIdentifier
      token: g
      element: <testLibrary>::@function::g
      staticType: (T, U) Function<T, U>()
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticInvokeType: (int, String) Function()
    staticType: (int, String)
    typeArgumentTypes
      int
      String
  patternTypeSchema: (int, String)
''');
  }
}
