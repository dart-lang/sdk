// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtractorPatternResolutionTest);
  });
}

@reflectiveTest
class ExtractorPatternResolutionTest extends PatternsResolutionTest {
  test_generic_noTypeArguments_infer_interfaceType() async {
    await assertNoErrorsInCode(r'''
class A<T> {}
class B<T> extends A<T> {}
void f(A<int> x) {
  switch (x) {
    case B():
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
      token: B
      staticElement: self::@class::B
      staticType: null
    type: B<int>
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_generic_noTypeArguments_infer_interfaceType_viaTypeAlias() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {}
class B<T, U> extends A<T, U> {}
typedef L<T> = B<T, String>;
void f(A<int, String> x) {
  switch (x) {
    case L():
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
      token: L
      staticElement: self::@typeAlias::L
      staticType: null
    type: B<int, String>
      alias: self::@typeAlias::L
        typeArguments
          int
  leftParenthesis: (
  rightParenthesis: )
''');
  }

  test_generic_withTypeArguments_hasName_variable_untyped() async {
    await assertNoErrorsInCode(r'''
abstract class A<T> {
  T get foo;
}

void f(x) {
  switch (x) {
    case A<int>(foo: var foo2):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      rightBracket: >
    type: A<int>
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: foo
        colon: :
      pattern: VariablePattern
        keyword: var
        name: foo2
        declaredElement: hasImplicitType foo2@90
          type: int
      fieldElement: PropertyAccessorMember
        base: self::@class::A::@getter::foo
        substitution: {T: int}
  rightParenthesis: )
''');
  }

  test_notGeneric_noTypeArguments_hasName_constant() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  int get foo;
}

void f(x) {
  switch (x) {
    case A(foo: 0):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    type: A
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
      fieldElement: self::@class::A::@getter::foo
  rightParenthesis: )
''');
  }

  test_notGeneric_noTypeArguments_hasName_extensionGetter() async {
    await assertNoErrorsInCode(r'''
abstract class A {}

extension E on A {
  int get foo => 0;
}

void f(x) {
  switch (x) {
    case A(foo: 0):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    type: A
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
      fieldElement: self::@extension::E::@getter::foo
  rightParenthesis: )
''');
  }

  test_notGeneric_noTypeArguments_hasName_variable_untyped() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  int get foo;
}

void f(x) {
  switch (x) {
    case A(foo: var foo2):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    type: A
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: foo
        colon: :
      pattern: VariablePattern
        keyword: var
        name: foo2
        declaredElement: hasImplicitType foo2@84
          type: int
      fieldElement: self::@class::A::@getter::foo
  rightParenthesis: )
''');
  }

  test_notGeneric_noTypeArguments_noName_variable() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  int get foo;
}

void f(x) {
  switch (x) {
    case A(: var foo):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    type: A
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        colon: :
      pattern: VariablePattern
        keyword: var
        name: foo
        declaredElement: hasImplicitType foo@81
          type: int
      fieldElement: self::@class::A::@getter::foo
  rightParenthesis: )
''');
  }

  test_notGeneric_noTypeArguments_noName_variable_nullCheck() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  int? get foo;
}

void f(x) {
  switch (x) {
    case A(: var foo?):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    type: A
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        colon: :
      pattern: PostfixPattern
        operand: VariablePattern
          keyword: var
          name: foo
          declaredElement: hasImplicitType foo@82
            type: int
        operator: ?
      fieldElement: self::@class::A::@getter::foo
  rightParenthesis: )
''');
  }

  test_notGeneric_noTypeArguments_noName_variable_parenthesis() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  int get foo;
}

void f(x) {
  switch (x) {
    case A(: (var foo)):
      break;
  }
}
''');
    final node = findNode.switchPatternCase('case').pattern;
    assertResolvedNodeText(node, r'''
ExtractorPattern
  type: NamedType
    name: SimpleIdentifier
      token: A
      staticElement: self::@class::A
      staticType: null
    type: A
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        colon: :
      pattern: ParenthesizedPattern
        leftParenthesis: (
        pattern: VariablePattern
          keyword: var
          name: foo
          declaredElement: hasImplicitType foo@82
            type: int
        rightParenthesis: )
      fieldElement: self::@class::A::@getter::foo
  rightParenthesis: )
''');
  }
}
