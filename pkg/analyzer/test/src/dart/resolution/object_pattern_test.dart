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
  test_class_generic_noTypeArguments_infer_f_bounded() async {
    await assertNoErrorsInCode(r'''
abstract class B<T extends B<T>> {}
abstract class C extends B<C> {}

void f(Object o) {
  switch (o) {
    case B():
  }
}
''');

    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: B
    element: <testLibraryFragment>::@class::B
    element2: <testLibraryFragment>::@class::B#element
    type: B<B<Object?>>
  leftParenthesis: (
  rightParenthesis: )
  matchedValueType: Object
''');
  }

  test_class_generic_noTypeArguments_infer_fromSuperType() async {
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
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: B
    element: <testLibraryFragment>::@class::B
    element2: <testLibraryFragment>::@class::B#element
    type: B<int>
  leftParenthesis: (
  rightParenthesis: )
  matchedValueType: A<int>
''');
  }

  test_class_generic_noTypeArguments_infer_partial_inference() async {
    await assertNoErrorsInCode(r'''
abstract class B<T> {}
abstract class C<T, U extends Set<T>> extends B<T> {}

void f(B<int> b) {
  switch (b) {
    case C():
  }
}
''');

    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: C
    element: <testLibraryFragment>::@class::C
    element2: <testLibraryFragment>::@class::C#element
    type: C<int, Set<int>>
  leftParenthesis: (
  rightParenthesis: )
  matchedValueType: B<int>
''');
  }

  test_class_generic_noTypeArguments_infer_useBounds() async {
    await assertNoErrorsInCode(r'''
class A<T extends num> {}

void f(Object? x) {
  switch (x) {
    case A():
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@class::A
    element2: <testLibraryFragment>::@class::A#element
    type: A<num>
  leftParenthesis: (
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_class_generic_noTypeArguments_infer_viaTypeAlias() async {
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
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: L
    element: <testLibraryFragment>::@typeAlias::L
    element2: <testLibraryFragment>::@typeAlias::L#element
    type: B<int, String>
      alias: <testLibraryFragment>::@typeAlias::L
        typeArguments
          int
  leftParenthesis: (
  rightParenthesis: )
  matchedValueType: A<int, String>
''');
  }

  test_class_generic_withTypeArguments_hasName_variable_untyped() async {
    await assertErrorsInCode(r'''
abstract class A<T> {
  T get foo;
}

void f(x) {
  switch (x) {
    case A<int>(foo: var foo2):
      break;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 90, 4),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    element: <testLibraryFragment>::@class::A
    element2: <testLibraryFragment>::@class::A#element
    type: A<int>
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: foo2
        declaredElement: hasImplicitType foo2@90
          type: int
        matchedValueType: int
      element: GetterMember
        base: <testLibraryFragment>::@class::A::@getter::foo
        substitution: {T: int}
      element2: <testLibraryFragment>::@class::A::@getter::foo#element
  rightParenthesis: )
  matchedValueType: dynamic
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
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@class::A
    element2: <testLibraryFragment>::@class::A#element
    type: A
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
        matchedValueType: int
      element: <testLibraryFragment>::@class::A::@getter::foo
      element2: <testLibraryFragment>::@class::A::@getter::foo#element
  rightParenthesis: )
  matchedValueType: dynamic
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
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@class::A
    element2: <testLibraryFragment>::@class::A#element
    type: A
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
        matchedValueType: int
      element: <testLibraryFragment>::@extension::E::@getter::foo
      element2: <testLibraryFragment>::@extension::E::@getter::foo#element
  rightParenthesis: )
  matchedValueType: dynamic
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
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 83, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@class::A
    element2: <testLibraryFragment>::@class::A#element
    type: A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@83
          type: void Function()
        matchedValueType: void Function()
      element: <testLibraryFragment>::@class::A::@method::foo
      element2: <testLibraryFragment>::@class::A::@method::foo#element
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_class_notGeneric_hasName_method_ofExtension() async {
    await assertErrorsInCode(r'''
class A {}

extension E on A {
  void foo() {}
}

void f(x) {
  switch (x) {
    case A(foo: var y):
      break;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 97, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@class::A
    element2: <testLibraryFragment>::@class::A#element
    type: A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@97
          type: void Function()
        matchedValueType: void Function()
      element: <testLibraryFragment>::@extension::E::@method::foo
      element2: <testLibraryFragment>::@extension::E::@method::foo#element
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_class_notGeneric_hasName_variable_untyped() async {
    await assertErrorsInCode(r'''
abstract class A {
  int get foo;
}

void f(x) {
  switch (x) {
    case A(foo: var foo2):
      break;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 84, 4),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@class::A
    element2: <testLibraryFragment>::@class::A#element
    type: A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: foo2
        declaredElement: hasImplicitType foo2@84
          type: int
        matchedValueType: int
      element: <testLibraryFragment>::@class::A::@getter::foo
      element2: <testLibraryFragment>::@class::A::@getter::foo#element
  rightParenthesis: )
  matchedValueType: dynamic
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
      error(CompileTimeErrorCode.MISSING_NAMED_PATTERN_FIELD_NAME, 75, 3),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@class::A
    element2: <testLibraryFragment>::@class::A#element
    type: A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
        matchedValueType: dynamic
      element: <null>
      element2: <null>
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_class_notGeneric_noName_variable() async {
    await assertErrorsInCode(r'''
abstract class A {
  int get foo;
}

void f(x) {
  switch (x) {
    case A(: var foo):
      break;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 81, 3),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@class::A
    element2: <testLibraryFragment>::@class::A#element
    type: A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: foo
        declaredElement: hasImplicitType foo@81
          type: int
        matchedValueType: int
      element: <testLibraryFragment>::@class::A::@getter::foo
      element2: <testLibraryFragment>::@class::A::@getter::foo#element
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_class_notGeneric_noName_variable_cast() async {
    await assertErrorsInCode(r'''
abstract class A {
  int? get foo;
}

void f(x) {
  switch (x) {
    case A(: var foo as int):
      break;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 82, 3),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@class::A
    element2: <testLibraryFragment>::@class::A#element
    type: A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: CastPattern
        pattern: DeclaredVariablePattern
          keyword: var
          name: foo
          declaredElement: hasImplicitType foo@82
            type: int
          matchedValueType: int
        asToken: as
        type: NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
        matchedValueType: int?
      element: <testLibraryFragment>::@class::A::@getter::foo
      element2: <testLibraryFragment>::@class::A::@getter::foo#element
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_class_notGeneric_noName_variable_nullAssert() async {
    await assertErrorsInCode(r'''
abstract class A {
  int? get foo;
}

void f(x) {
  switch (x) {
    case A(: var foo!):
      break;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 82, 3),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@class::A
    element2: <testLibraryFragment>::@class::A#element
    type: A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: NullAssertPattern
        pattern: DeclaredVariablePattern
          keyword: var
          name: foo
          declaredElement: hasImplicitType foo@82
            type: int
          matchedValueType: int
        operator: !
        matchedValueType: int?
      element: <testLibraryFragment>::@class::A::@getter::foo
      element2: <testLibraryFragment>::@class::A::@getter::foo#element
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_class_notGeneric_noName_variable_nullCheck() async {
    await assertErrorsInCode(r'''
abstract class A {
  int? get foo;
}

void f(x) {
  switch (x) {
    case A(: var foo?):
      break;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 82, 3),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@class::A
    element2: <testLibraryFragment>::@class::A#element
    type: A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: NullCheckPattern
        pattern: DeclaredVariablePattern
          keyword: var
          name: foo
          declaredElement: hasImplicitType foo@82
            type: int
          matchedValueType: int
        operator: ?
        matchedValueType: int?
      element: <testLibraryFragment>::@class::A::@getter::foo
      element2: <testLibraryFragment>::@class::A::@getter::foo#element
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_class_notGeneric_noName_variable_parenthesis() async {
    await assertErrorsInCode(r'''
abstract class A {
  int get foo;
}

void f(x) {
  switch (x) {
    case A(: (var foo)):
      break;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 82, 3),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@class::A
    element2: <testLibraryFragment>::@class::A#element
    type: A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: ParenthesizedPattern
        leftParenthesis: (
        pattern: DeclaredVariablePattern
          keyword: var
          name: foo
          declaredElement: hasImplicitType foo@82
            type: int
          matchedValueType: int
        rightParenthesis: )
        matchedValueType: int
      element: <testLibraryFragment>::@class::A::@getter::foo
      element2: <testLibraryFragment>::@class::A::@getter::foo#element
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_class_notGeneric_positionalField() async {
    await assertErrorsInCode(r'''
void f(Object? x) {
  if (x case Object(0)) {}
}
''', [
      error(CompileTimeErrorCode.POSITIONAL_FIELD_IN_OBJECT_PATTERN, 40, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: Object
    element: dart:core::<fragment>::@class::Object
    element2: dart:core::<fragment>::@class::Object#element
    type: Object
  leftParenthesis: (
  fields
    PatternField
      pattern: ConstantPattern
        expression: IntegerLiteral
          literal: 0
          staticType: int
        matchedValueType: dynamic
      element: <null>
      element2: <null>
  rightParenthesis: )
  matchedValueType: Object?
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
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@class::A
    element2: <testLibraryFragment>::@class::A#element
    type: A
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
        matchedValueType: dynamic
      element: <null>
      element2: <null>
  rightParenthesis: )
  matchedValueType: dynamic
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
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 65, 3),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@class::A
    element2: <testLibraryFragment>::@class::A#element
    type: A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: foo
        declaredElement: hasImplicitType foo@65
          type: dynamic
        matchedValueType: dynamic
      element: <null>
      element2: <null>
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_extensionType_notGeneric_hasName_constant() async {
    await assertNoErrorsInCode(r'''
extension type A(int it) {
  int get foo => 0;
}

void f(x) {
  switch (x) {
    case A(foo: 0):
      break;
  }
}
''');
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@extensionType::A
    element2: <testLibraryFragment>::@extensionType::A#element
    type: A
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
        matchedValueType: int
      element: <testLibraryFragment>::@extensionType::A::@getter::foo
      element2: <testLibraryFragment>::@extensionType::A::@getter::foo#element
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_extensionType_notGeneric_noName_variable() async {
    await assertErrorsInCode(r'''
extension type A(int it) {
  int get foo => 0;
}

void f(x) {
  switch (x) {
    case A(: final foo):
      break;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 96, 3),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@extensionType::A
    element2: <testLibraryFragment>::@extensionType::A#element
    type: A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: DeclaredVariablePattern
        keyword: final
        name: foo
        declaredElement: hasImplicitType isFinal foo@96
          type: int
        matchedValueType: int
      element: <testLibraryFragment>::@extensionType::A::@getter::foo
      element2: <testLibraryFragment>::@extensionType::A::@getter::foo#element
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_extensionType_notGeneric_unresolved_hasName() async {
    await assertErrorsInCode(r'''
extension type A(int it) {}

void f(x) {
  switch (x) {
    case A(foo: 0):
      break;
  }
}
''', [
      error(CompileTimeErrorCode.UNDEFINED_GETTER, 67, 3),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@extensionType::A
    element2: <testLibraryFragment>::@extensionType::A#element
    type: A
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
        matchedValueType: dynamic
      element: <null>
      element2: <null>
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_typeAlias_nullable() async {
    await assertErrorsInCode(r'''
typedef A = int?;

void f(x) {
  switch (x) {
    case A(foo: 0):
      break;
  }
}
''', [
      error(CompileTimeErrorCode.UNCHECKED_PROPERTY_ACCESS_OF_NULLABLE_VALUE,
          55, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@typeAlias::A
    element2: <testLibraryFragment>::@typeAlias::A#element
    type: int?
      alias: <testLibraryFragment>::@typeAlias::A
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
        matchedValueType: dynamic
      element: <null>
      element2: <null>
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_typedef_dynamic_hasName_unresolved() async {
    await assertErrorsInCode(r'''
typedef A = dynamic;

void f(Object? x) {
  switch (x) {
    case A(foo: var y):
      break;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 77, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@typeAlias::A
    element2: <testLibraryFragment>::@typeAlias::A#element
    type: dynamic
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@77
          type: dynamic
        matchedValueType: dynamic
      element: <null>
      element2: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_typedef_functionType_generic_withTypeArguments_hasName_extensionGetter() async {
    await assertErrorsInCode(r'''
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
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 145, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::<fragment>::@class::int
          element2: dart:core::<fragment>::@class::int#element
          type: int
      rightBracket: >
    element: <testLibraryFragment>::@typeAlias::A
    element2: <testLibraryFragment>::@typeAlias::A#element
    type: int Function()
      alias: <testLibraryFragment>::@typeAlias::A
        typeArguments
          int
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@145
          type: int
        matchedValueType: int
      element: <testLibraryFragment>::@extension::E::@getter::foo
      element2: <testLibraryFragment>::@extension::E::@getter::foo#element
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_typedef_functionType_notGeneric_hasName_extensionGetter() async {
    await assertErrorsInCode(r'''
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
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 141, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@typeAlias::A
    element2: <testLibraryFragment>::@typeAlias::A#element
    type: void Function()
      alias: <testLibraryFragment>::@typeAlias::A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@141
          type: int
        matchedValueType: int
      element: <testLibraryFragment>::@extension::E::@getter::foo
      element2: <testLibraryFragment>::@extension::E::@getter::foo#element
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_typedef_functionType_notGeneric_hasName_hashCode() async {
    await assertErrorsInCode(r'''
typedef A = void Function();

void f(Object? x) {
  switch (x) {
    case A(hashCode: var y):
      break;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 90, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@typeAlias::A
    element2: <testLibraryFragment>::@typeAlias::A#element
    type: void Function()
      alias: <testLibraryFragment>::@typeAlias::A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: hashCode
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@90
          type: int
        matchedValueType: int
      element: dart:core::<fragment>::@class::Object::@getter::hashCode
      element2: dart:core::<fragment>::@class::Object::@getter::hashCode#element
  rightParenthesis: )
  matchedValueType: Object?
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
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 85, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@typeAlias::A
    element2: <testLibraryFragment>::@typeAlias::A#element
    type: void Function()
      alias: <testLibraryFragment>::@typeAlias::A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@85
          type: dynamic
        matchedValueType: dynamic
      element: <null>
      element2: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_typedef_recordType_notGeneric_hasName_named() async {
    await assertErrorsInCode(r'''
typedef A = ({int foo});

void f(x) {
  switch (x) {
    case A(foo: var y):
      break;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 73, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@typeAlias::A
    element2: <testLibraryFragment>::@typeAlias::A#element
    type: ({int foo})
      alias: <testLibraryFragment>::@typeAlias::A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@73
          type: int
        matchedValueType: int
      element: <null>
      element2: <null>
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_typedef_recordType_notGeneric_hasName_positional() async {
    await assertErrorsInCode(r'''
typedef A = (int foo,);

void f(x) {
  switch (x) {
    case A($1: var y):
      break;
  }
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 71, 1),
    ]);
    var node = findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibraryFragment>::@typeAlias::A
    element2: <testLibraryFragment>::@typeAlias::A#element
    type: (int,)
      alias: <testLibraryFragment>::@typeAlias::A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: $1
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredElement: hasImplicitType y@71
          type: int
        matchedValueType: int
      element: <null>
      element2: <null>
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_variableDeclaration_inferredType() async {
    await assertErrorsInCode(r'''
void f(A<int> x) {
  var A(foo: a) = x;
}

class A<T> {
  T get foo => throw 0;
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 32, 1),
    ]);
    var node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ObjectPattern
    type: NamedType
      name: A
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: A<int>
    leftParenthesis: (
    fields
      PatternField
        name: PatternFieldName
          name: foo
          colon: :
        pattern: DeclaredVariablePattern
          name: a
          declaredElement: hasImplicitType a@32
            type: int
          matchedValueType: int
        element: GetterMember
          base: <testLibraryFragment>::@class::A::@getter::foo
          substitution: {T: int}
        element2: <testLibraryFragment>::@class::A::@getter::foo#element
    rightParenthesis: )
    matchedValueType: A<int>
  equals: =
  expression: SimpleIdentifier
    token: x
    staticElement: <testLibraryFragment>::@function::f::@parameter::x
    element: <testLibraryFragment>::@function::f::@parameter::x#element
    staticType: A<int>
  patternTypeSchema: A<dynamic>
''');
  }

  // TODO(scheglov): Remove `new` (everywhere), implement rewrite.
  test_variableDeclaration_typeSchema_withTypeArguments() async {
    await assertErrorsInCode(r'''
void f() {
  var A<int>(foo: a) = new A();
}

class A<T> {
  T get foo => throw 0;
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 29, 1),
    ]);
    var node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ObjectPattern
    type: NamedType
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
        rightBracket: >
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: A<int>
    leftParenthesis: (
    fields
      PatternField
        name: PatternFieldName
          name: foo
          colon: :
        pattern: DeclaredVariablePattern
          name: a
          declaredElement: hasImplicitType a@29
            type: int
          matchedValueType: int
        element: GetterMember
          base: <testLibraryFragment>::@class::A::@getter::foo
          substitution: {T: int}
        element2: <testLibraryFragment>::@class::A::@getter::foo#element
    rightParenthesis: )
    matchedValueType: A<int>
  equals: =
  expression: InstanceCreationExpression
    keyword: new
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: <testLibraryFragment>::@class::A
        element2: <testLibraryFragment>::@class::A#element
        type: A<int>
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::new
        substitution: {T: int}
      element: <testLibraryFragment>::@class::A::@constructor::new#element
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A<int>
  patternTypeSchema: A<int>
''');
  }

  test_variableDeclaration_typeSchema_withVariableType() async {
    // `int a` does not propagate up, we get `A<dynamic>`
    await assertErrorsInCode(r'''
void f() {
  var A(foo: int a) = new A();
}

class A<T> {
  T get foo => throw 0;
}
''', [
      error(WarningCode.UNUSED_LOCAL_VARIABLE, 28, 1),
    ]);
    var node = findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ObjectPattern
    type: NamedType
      name: A
      element: <testLibraryFragment>::@class::A
      element2: <testLibraryFragment>::@class::A#element
      type: A<dynamic>
    leftParenthesis: (
    fields
      PatternField
        name: PatternFieldName
          name: foo
          colon: :
        pattern: DeclaredVariablePattern
          type: NamedType
            name: int
            element: dart:core::<fragment>::@class::int
            element2: dart:core::<fragment>::@class::int#element
            type: int
          name: a
          declaredElement: a@28
            type: int
          matchedValueType: dynamic
        element: GetterMember
          base: <testLibraryFragment>::@class::A::@getter::foo
          substitution: {T: dynamic}
        element2: <testLibraryFragment>::@class::A::@getter::foo#element
    rightParenthesis: )
    matchedValueType: A<dynamic>
  equals: =
  expression: InstanceCreationExpression
    keyword: new
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: <testLibraryFragment>::@class::A
        element2: <testLibraryFragment>::@class::A#element
        type: A<dynamic>
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::new
        substitution: {T: dynamic}
      element: <testLibraryFragment>::@class::A::@constructor::new#element
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A<dynamic>
  patternTypeSchema: A<dynamic>
''');
  }
}
