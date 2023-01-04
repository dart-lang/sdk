// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ObjectPatternResolutionTest);
  });
}

@reflectiveTest
class ObjectPatternResolutionTest extends PubPackageResolutionTest {
  test_class_generic_noTypeArguments_infer_interfaceType() async {
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
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
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

  test_class_generic_noTypeArguments_infer_interfaceType_viaTypeAlias() async {
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
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
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

  test_class_generic_withTypeArguments_hasName_variable_untyped() async {
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
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
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
      pattern: DeclaredVariablePattern
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

  test_class_notGeneric_hasName_constant() async {
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
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
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

  test_class_notGeneric_hasName_extensionGetter() async {
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
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
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

  test_class_notGeneric_hasName_method() async {
    await assertErrorsInCode(r'''
abstract class A {
  void foo();
}

void f(x) {
  switch (x) {
    case A(foo: var y):
      break;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 74, 3),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
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
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@83
          type: void Function()
      fieldElement: self::@class::A::@method::foo
  rightParenthesis: )
''');
  }

  test_class_notGeneric_hasName_variable_untyped() async {
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
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
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
      pattern: DeclaredVariablePattern
        keyword: var
        name: foo2
        declaredElement: hasImplicitType foo2@84
          type: int
      fieldElement: self::@class::A::@getter::foo
  rightParenthesis: )
''');
  }

  test_class_notGeneric_noName_constant() async {
    await assertErrorsInCode(r'''
abstract class A {
  int get foo;
}

void f(x) {
  switch (x) {
    case A(: 0):
      break;
  }
}
''', [
      error(CompileTimeErrorCode.MISSING_OBJECT_PATTERN_GETTER_NAME, 75, 3),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
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
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
      fieldElement: <null>
  rightParenthesis: )
''');
  }

  test_class_notGeneric_noName_variable() async {
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
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
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
      pattern: DeclaredVariablePattern
        keyword: var
        name: foo
        declaredElement: hasImplicitType foo@81
          type: int
      fieldElement: self::@class::A::@getter::foo
  rightParenthesis: )
''');
  }

  test_class_notGeneric_noName_variable_cast() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  int? get foo;
}

void f(x) {
  switch (x) {
    case A(: var foo as int):
      break;
  }
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
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
      pattern: CastPattern
        pattern: DeclaredVariablePattern
          keyword: var
          name: foo
          declaredElement: hasImplicitType foo@82
            type: int
        asToken: as
        type: NamedType
          name: SimpleIdentifier
            token: int
            staticElement: dart:core::@class::int
            staticType: null
          type: int
      fieldElement: self::@class::A::@getter::foo
  rightParenthesis: )
''');
  }

  test_class_notGeneric_noName_variable_nullAssert() async {
    await assertNoErrorsInCode(r'''
abstract class A {
  int? get foo;
}

void f(x) {
  switch (x) {
    case A(: var foo!):
      break;
  }
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
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
        operand: DeclaredVariablePattern
          keyword: var
          name: foo
          declaredElement: hasImplicitType foo@82
            type: int
        operator: !
      fieldElement: self::@class::A::@getter::foo
  rightParenthesis: )
''');
  }

  test_class_notGeneric_noName_variable_nullCheck() async {
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
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
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
        operand: DeclaredVariablePattern
          keyword: var
          name: foo
          declaredElement: hasImplicitType foo@82
            type: int
        operator: ?
      fieldElement: self::@class::A::@getter::foo
  rightParenthesis: )
''');
  }

  test_class_notGeneric_noName_variable_parenthesis() async {
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
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
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
        pattern: DeclaredVariablePattern
          keyword: var
          name: foo
          declaredElement: hasImplicitType foo@82
            type: int
        rightParenthesis: )
      fieldElement: self::@class::A::@getter::foo
  rightParenthesis: )
''');
  }

  test_class_notGeneric_unresolved_hasName() async {
    await assertErrorsInCode(r'''
abstract class A {}

void f(x) {
  switch (x) {
    case A(foo: 0):
      break;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 59, 3),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
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
      fieldElement: <null>
  rightParenthesis: )
''');
  }

  test_class_notGeneric_unresolved_noName() async {
    await assertErrorsInCode(r'''
abstract class A {}

void f(x) {
  switch (x) {
    case A(: var foo):
      break;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 65, 3),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
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
      pattern: DeclaredVariablePattern
        keyword: var
        name: foo
        declaredElement: hasImplicitType foo@65
          type: dynamic
      fieldElement: <null>
  rightParenthesis: )
''');
  }

  test_typedef_dynamic_hasName_unresolved() async {
    await assertNoErrorsInCode(r'''
typedef A = dynamic;

void f(Object? x) {
  switch (x) {
    case A(foo: var y):
      break;
  }
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: SimpleIdentifier
      token: A
      staticElement: self::@typeAlias::A
      staticType: null
    type: dynamic
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@77
          type: dynamic
      fieldElement: <null>
  rightParenthesis: )
''');
  }

  test_typedef_functionType_generic_withTypeArguments_hasName_extensionGetter() async {
    await assertNoErrorsInCode(r'''
typedef A<T> = T Function();

extension E on int Function() {
  int get foo => 0;
}

void f(Object? x) {
  switch (x) {
    case A<int>(foo: var y):
      break;
  }
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: SimpleIdentifier
      token: A
      staticElement: self::@typeAlias::A
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
    type: int Function()
      alias: self::@typeAlias::A
        typeArguments
          int
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@145
          type: int
      fieldElement: self::@extension::E::@getter::foo
  rightParenthesis: )
''');
  }

  test_typedef_functionType_notGeneric_hasName_extensionGetter() async {
    await assertNoErrorsInCode(r'''
typedef A = void Function();

extension E on void Function() {
  int get foo => 0;
}

void f(Object? x) {
  switch (x) {
    case A(foo: var y):
      break;
  }
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: SimpleIdentifier
      token: A
      staticElement: self::@typeAlias::A
      staticType: null
    type: void Function()
      alias: self::@typeAlias::A
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@141
          type: int
      fieldElement: self::@extension::E::@getter::foo
  rightParenthesis: )
''');
  }

  test_typedef_functionType_notGeneric_hasName_hashCode() async {
    await assertNoErrorsInCode(r'''
typedef A = void Function();

void f(Object? x) {
  switch (x) {
    case A(hashCode: var y):
      break;
  }
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: SimpleIdentifier
      token: A
      staticElement: self::@typeAlias::A
      staticType: null
    type: void Function()
      alias: self::@typeAlias::A
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: hashCode
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@90
          type: int
      fieldElement: dart:core::@class::Object::@getter::hashCode
  rightParenthesis: )
''');
  }

  test_typedef_functionType_notGeneric_hasName_unresolved() async {
    await assertErrorsInCode(r'''
typedef A = void Function();

void f(Object? x) {
  switch (x) {
    case A(foo: var y):
      break;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 76, 3),
    ]);
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: SimpleIdentifier
      token: A
      staticElement: self::@typeAlias::A
      staticType: null
    type: void Function()
      alias: self::@typeAlias::A
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@85
          type: dynamic
      fieldElement: <null>
  rightParenthesis: )
''');
  }

  test_typedef_recordType_notGeneric_hasName_named() async {
    await assertNoErrorsInCode(r'''
typedef A = ({int foo});

void f(x) {
  switch (x) {
    case A(foo: var y):
      break;
  }
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: SimpleIdentifier
      token: A
      staticElement: self::@typeAlias::A
      staticType: null
    type: ({int foo})
      alias: self::@typeAlias::A
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@73
          type: int
      fieldElement: <null>
  rightParenthesis: )
''');
  }

  test_typedef_recordType_notGeneric_hasName_positional() async {
    await assertNoErrorsInCode(r'''
typedef A = (int foo,);

void f(x) {
  switch (x) {
    case A($0: var y):
      break;
  }
}
''');
    final node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: SimpleIdentifier
      token: A
      staticElement: self::@typeAlias::A
      staticType: null
    type: (int)
      alias: self::@typeAlias::A
  leftParenthesis: (
  fields
    RecordPatternField
      fieldName: RecordPatternFieldName
        name: $0
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@71
          type: int
      fieldElement: <null>
  rightParenthesis: )
''');
  }

  test_variableDeclaration_inferredType() async {
    await assertNoErrorsInCode(r'''
void f(A<int> x) {
  var A(foo: a) = x;
}

class A<T> {
  T get foo => throw 0;
}
''');
    final node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ObjectPattern
    type: NamedType
      name: SimpleIdentifier
        token: A
        staticElement: self::@class::A
        staticType: null
      type: A<int>
    leftParenthesis: (
    fields
      RecordPatternField
        fieldName: RecordPatternFieldName
          name: foo
          colon: :
        pattern: DeclaredVariablePattern
          name: a
          declaredElement: hasImplicitType a@32
            type: int
        fieldElement: PropertyAccessorMember
          base: self::@class::A::@getter::foo
          substitution: {T: int}
    rightParenthesis: )
  equals: =
  expression: SimpleIdentifier
    token: x
    staticElement: self::@function::f::@parameter::x
    staticType: A<int>
''');
  }

  /// TODO(scheglov) Remove `new` (everywhere), implement rewrite.
  test_variableDeclaration_typeSchema_withTypeArguments() async {
    await assertNoErrorsInCode(r'''
void f() {
  var A<int>(foo: a) = new A();
}

class A<T> {
  T get foo => throw 0;
}
''');
    final node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ObjectPattern
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
        pattern: DeclaredVariablePattern
          name: a
          declaredElement: hasImplicitType a@29
            type: int
        fieldElement: PropertyAccessorMember
          base: self::@class::A::@getter::foo
          substitution: {T: int}
    rightParenthesis: )
  equals: =
  expression: InstanceCreationExpression
    keyword: new
    constructorName: ConstructorName
      type: NamedType
        name: SimpleIdentifier
          token: A
          staticElement: self::@class::A
          staticType: null
        type: A<int>
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::new
        substitution: {T: int}
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A<int>
''');
  }

  test_variableDeclaration_typeSchema_withVariableType() async {
    // `int a` does not propagate up, we get `A<dynamic>`
    await assertNoErrorsInCode(r'''
void f() {
  var A(foo: int a) = new A();
}

class A<T> {
  T get foo => throw 0;
}
''');
    final node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ObjectPattern
    type: NamedType
      name: SimpleIdentifier
        token: A
        staticElement: self::@class::A
        staticType: null
      type: A<dynamic>
    leftParenthesis: (
    fields
      RecordPatternField
        fieldName: RecordPatternFieldName
          name: foo
          colon: :
        pattern: DeclaredVariablePattern
          type: NamedType
            name: SimpleIdentifier
              token: int
              staticElement: dart:core::@class::int
              staticType: null
            type: int
          name: a
          declaredElement: a@28
            type: int
        fieldElement: PropertyAccessorMember
          base: self::@class::A::@getter::foo
          substitution: {T: dynamic}
    rightParenthesis: )
  equals: =
  expression: InstanceCreationExpression
    keyword: new
    constructorName: ConstructorName
      type: NamedType
        name: SimpleIdentifier
          token: A
          staticElement: self::@class::A
          staticType: null
        type: A<dynamic>
      staticElement: ConstructorMember
        base: self::@class::A::@constructor::new
        substitution: {T: dynamic}
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A<dynamic>
''');
  }
}
