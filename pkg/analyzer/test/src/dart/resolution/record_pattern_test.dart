// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RecordPatternResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class RecordPatternResolutionTest extends PubPackageResolutionTest {
  test_dynamicType_empty() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  switch (x) {
    case ():
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_dynamicType_named_variable_untyped() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  switch (x) {
    case (foo: var y):
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
      element: <null>
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_dynamicType_positional_variable_untyped() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(x) {
  switch (x) {
    case (var y,):
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
      element: <null>
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_interfaceType_empty() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case ():
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_interfaceType_named_constant() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case (foo: 0):
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
      element: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_interfaceType_named_variable_typed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case (foo: int y):
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
          element: dart:core::@class::int
          type: int
        name: y
        declaredFragment: isPublic y@54
          element: isPublic
            type: int
        matchedValueType: Object?
      element: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_interfaceType_named_variable_untyped() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case (foo: var y):
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
      element: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_interfaceType_positional_constant() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case (0,):
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
      element: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_interfaceType_positional_variable_typed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case (int y,):
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    PatternField
      pattern: DeclaredVariablePattern
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        name: y
        declaredFragment: isPublic y@49
          element: isPublic
            type: int
        matchedValueType: Object?
      element: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_interfaceType_positional_variable_untyped() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  switch (x) {
    case (var y,):
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
      element: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_recordType_differentShape_named_tooFew_hasName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(() x) {
  switch (x) {
    case (a: var b):
//       ^^^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type '()' can never match the required type '({Object? a})'.
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
      break;
    default:
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
      element: <null>
  rightParenthesis: )
  matchedValueType: ()
''');
  }

  test_recordType_differentShape_named_tooFew_noName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(() x) {
  switch (x) {
    case (: var a):
//       ^^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type '()' can never match the required type '({Object? a})'.
//              ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
    default:
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
      element: <null>
  rightParenthesis: )
  matchedValueType: ()
''');
  }

  test_recordType_differentShape_named_tooFew_noName2() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(({int b}) x) {
  switch (x) {
    case (: var a):
//       ^^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type '({int b})' can never match the required type '({Object? a})'.
//              ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
      element: <null>
  rightParenthesis: )
  matchedValueType: ({int b})
''');
  }

  test_recordType_differentShape_named_tooMany_noName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(({int a, int b}) x) {
  switch (x) {
    case (: var a):
//       ^^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type '({int a, int b})' can never match the required type '({Object? a})'.
//              ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
      element: <null>
  rightParenthesis: )
  matchedValueType: ({int a, int b})
''');
  }

  test_recordType_differentShape_positional_tooFew() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(() x) {
  switch (x) {
    case (var a,):
//       ^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type '()' can never match the required type '(Object?,)'.
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
    default:
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
      element: <null>
  rightParenthesis: )
  matchedValueType: ()
''');
  }

  test_recordType_differentShape_positional_tooMany() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, String) x) {
  switch (x) {
    case (var a,):
//       ^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type '(int, String)' can never match the required type '(Object?,)'.
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
      element: <null>
  rightParenthesis: )
  matchedValueType: (int, String)
''');
  }

  test_recordType_sameShape_empty() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(() x) {
  switch (x) {
    case ():
      break;
    default:
//  ^^^^^^^
// [diag.deadCode] Dead code.
// [diag.unreachableSwitchDefault] This default clause is covered by the previous cases.
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  rightParenthesis: )
  matchedValueType: ()
''');
  }

  test_recordType_sameShape_mixed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, double, {String foo}) x) {
  switch (x) {
    case (var a, foo: var b, var c):
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//                        ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
//                               ^
// [diag.unusedLocalVariable] The value of the local variable 'c' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
      element: <null>
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
      element: <null>
    PatternField
      pattern: DeclaredVariablePattern
        keyword: var
        name: c
        declaredFragment: isPublic c@88
          element: hasImplicitType isPublic
            type: double
        matchedValueType: double
      element: <null>
  rightParenthesis: )
  matchedValueType: (int, double, {String foo})
''');
  }

  test_recordType_sameShape_named_hasName_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(({int foo}) x) {
  switch (x) {
    case (bar: var a):
//       ^^^^^^^^^^^^
// [diag.patternNeverMatchesValueType] The matched value type '({int foo})' can never match the required type '({Object? bar})'.
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
      element: <null>
  rightParenthesis: )
  matchedValueType: ({int foo})
''');
  }

  test_recordType_sameShape_named_hasName_variable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(({int foo}) x) {
  switch (x) {
    case (foo: var y):
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
      element: <null>
  rightParenthesis: )
  matchedValueType: ({int foo})
''');
  }

  test_recordType_sameShape_named_noName_constant() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(({int foo}) x) {
  switch (x) {
    case (: 0):
//       ^^^^^
// [diag.patternNeverMatchesValueType] The matched value type '({int foo})' can never match the required type '(Object?,)'.
//        ^^^
// [diag.missingNamedPatternFieldName] The getter name is not specified explicitly, and the pattern is not a variable.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
      element: <null>
  rightParenthesis: )
  matchedValueType: ({int foo})
''');
  }

  test_recordType_sameShape_named_noName_variable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(({int foo}) x) {
  switch (x) {
    case (: var foo):
//              ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
      element: <null>
  rightParenthesis: )
  matchedValueType: ({int foo})
''');
  }

  test_recordType_sameShape_named_noName_variable_cast() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(({int? foo}) x) {
  switch (x) {
    case (: var foo as int):
//              ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
          element: dart:core::@class::int
          type: int
        matchedValueType: int?
      element: <null>
  rightParenthesis: )
  matchedValueType: ({int? foo})
''');
  }

  test_recordType_sameShape_named_noName_variable_nullAssert() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(({int? foo}) x) {
  switch (x) {
    case (: var foo!):
//              ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
      element: <null>
  rightParenthesis: )
  matchedValueType: ({int? foo})
''');
  }

  test_recordType_sameShape_named_noName_variable_nullCheck() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(({int? foo}) x) {
  switch (x) {
    case (: var foo?):
//              ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
      element: <null>
  rightParenthesis: )
  matchedValueType: ({int? foo})
''');
  }

  test_recordType_sameShape_positional_variable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int,) x) {
  switch (x) {
    case (var a,):
//            ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
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
      element: <null>
  rightParenthesis: )
  matchedValueType: (int,)
''');
  }

  test_variableDeclaration_inferredType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f((int, String) x) {
  var (a, b) = x;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//        ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
}
''');
    var node = result.findNode.singlePatternVariableDeclaration;
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
        element: <null>
      PatternField
        pattern: DeclaredVariablePattern
          name: b
          declaredFragment: isPublic b@36
            element: hasImplicitType isPublic
              type: String
          matchedValueType: String
        element: <null>
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
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var (int a, String b) = g();
//         ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
//                   ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
}

(T, U) g<T, U>() => throw 0;
''');
    var node = result.findNode.singlePatternVariableDeclaration;
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
            element: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@22
            element: isPublic
              type: int
          matchedValueType: int
        element: <null>
      PatternField
        pattern: DeclaredVariablePattern
          type: NamedType
            name: String
            element: dart:core::@class::String
            type: String
          name: b
          declaredFragment: isPublic b@32
            element: isPublic
              type: String
          matchedValueType: String
        element: <null>
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
