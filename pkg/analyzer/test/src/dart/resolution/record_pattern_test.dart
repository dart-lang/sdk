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
class RecordPatternResolutionTest extends PatternsResolutionTest {
  test_dynamicType_empty() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case ():
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_dynamicType_named_variable_untyped() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (foo: var y):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: foo
        colon: :
      pattern: VariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@46
          type: dynamic
      fieldElement: <null>
  rightParenthesis: )
''');
  }

  test_dynamicType_positional_variable_untyped() async {
    await assertNoErrorsInCode(r'''
void f(x) {
  switch (x) {
    case (var y):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ParenthesizedPattern
  leftParenthesis: (
  pattern: VariablePattern
    keyword: var
    name: y
    declaredElement: hasImplicitType y@41
      type: dynamic
  rightParenthesis: )
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
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  rightParenthesis: )
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
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: foo
        colon: :
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
      fieldElement: <null>
  rightParenthesis: )
''');
  }

  test_interfaceType_named_variable_typed() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case (foo: int y):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: foo
        colon: :
      pattern: VariablePattern
        type: NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
        name: y
        declaredElement: y@54
          type: int
      fieldElement: <null>
  rightParenthesis: )
''');
  }

  test_interfaceType_named_variable_untyped() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case (foo: var y):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: foo
        colon: :
      pattern: VariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@54
          type: Object?
      fieldElement: <null>
  rightParenthesis: )
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
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
      fieldElement: <null>
  rightParenthesis: )
''');
  }

  test_interfaceType_positional_variable_typed() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case (int y,):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      pattern: VariablePattern
        type: NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
        name: y
        declaredElement: y@49
          type: int
      fieldElement: <null>
  rightParenthesis: )
''');
  }

  test_interfaceType_positional_variable_untyped() async {
    await assertNoErrorsInCode(r'''
void f(Object? x) {
  switch (x) {
    case (var y,):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      pattern: VariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@49
          type: Object?
      fieldElement: <null>
  rightParenthesis: )
''');
  }

  test_recordType_empty() async {
    await assertNoErrorsInCode(r'''
void f(() x) {
  switch (x) {
    case ():
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_recordType_mixed() async {
    await assertNoErrorsInCode(r'''
void f((int, double, {String foo}) x) {
  switch (x) {
    case (var a, foo: var b, var c):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      pattern: VariablePattern
        keyword: var
        name: a
        declaredElement: hasImplicitType a@69
          type: int
      fieldElement: <null>
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: foo
        colon: :
      pattern: VariablePattern
        keyword: var
        name: b
        declaredElement: hasImplicitType b@81
          type: String
      fieldElement: <null>
    RecordPatternField
      pattern: VariablePattern
        keyword: var
        name: c
        declaredElement: hasImplicitType c@88
          type: double
      fieldElement: <null>
  rightParenthesis: )
''');
  }

  test_recordType_named_hasName_unresolved() async {
    await assertNoErrorsInCode(r'''
void f(({int foo}) x) {
  switch (x) {
    case (bar: var a):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: bar
        colon: :
      pattern: VariablePattern
        keyword: var
        name: a
        declaredElement: hasImplicitType a@58
          type: Object?
      fieldElement: <null>
  rightParenthesis: )
''');
  }

  test_recordType_named_hasName_variable() async {
    await assertNoErrorsInCode(r'''
void f(({int foo}) x) {
  switch (x) {
    case (foo: var y):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: foo
        colon: :
      pattern: VariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@58
          type: int
      fieldElement: <null>
  rightParenthesis: )
''');
  }

  test_recordType_named_noName_constant() async {
    await assertErrorsInCode(r'''
void f(({int foo}) x) {
  switch (x) {
    case (: 0):
      break;
  }
}
''', [
      error(CompileTimeErrorCode.MISSING_EXTRACTOR_PATTERN_GETTER_NAME, 49, 3),
    ]);
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        colon: :
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
      fieldElement: <null>
  rightParenthesis: )
''');
  }

  test_recordType_named_noName_variable() async {
    await assertNoErrorsInCode(r'''
void f(({int foo}) x) {
  switch (x) {
    case (: var foo):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        colon: :
      pattern: VariablePattern
        keyword: var
        name: foo
        declaredElement: hasImplicitType foo@55
          type: int
      fieldElement: <null>
  rightParenthesis: )
''');
  }

  test_recordType_named_noName_variable_nullCheck() async {
    await assertNoErrorsInCode(r'''
void f(({int? foo}) x) {
  switch (x) {
    case (: var foo?):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        colon: :
      pattern: PostfixPattern
        operand: VariablePattern
          keyword: var
          name: foo
          declaredElement: hasImplicitType foo@56
            type: int
        operator: ?
      fieldElement: <null>
  rightParenthesis: )
''');
  }

  test_recordType_positional_tooMany() async {
    await assertNoErrorsInCode(r'''
void f((int,) x) {
  switch (x) {
    case (var a, var b):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      pattern: VariablePattern
        keyword: var
        name: a
        declaredElement: hasImplicitType a@48
          type: int
      fieldElement: <null>
    RecordPatternField
      pattern: VariablePattern
        keyword: var
        name: b
        declaredElement: hasImplicitType b@55
          type: Object?
      fieldElement: <null>
  rightParenthesis: )
''');
  }

  test_recordType_positional_variable() async {
    await assertNoErrorsInCode(r'''
void f((int,) x) {
  switch (x) {
    case (var a,):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
RecordPattern
  leftParenthesis: (
  fields
    RecordPatternField
      pattern: VariablePattern
        keyword: var
        name: a
        declaredElement: hasImplicitType a@48
          type: int
      fieldElement: <null>
  rightParenthesis: )
''');
  }
}
