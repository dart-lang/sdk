// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ObjectPatternResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ObjectPatternResolutionTest extends PubPackageResolutionTest {
  test_class_generic_noTypeArguments_infer_f_bounded() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class B<T extends B<T>> {}
abstract class C extends B<C> {}

void f(Object o) {
  switch (o) {
    case B():
  }
}
''');

    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: B
    element: <testLibrary>::@class::B
    type: B<B<Object?>>
  leftParenthesis: (
  rightParenthesis: )
  matchedValueType: Object
''');
  }

  test_class_generic_noTypeArguments_infer_fromSuperType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {}
class B<T> extends A<T> {}
void f(A<int> x) {
  switch (x) {
    case B():
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: B
    element: <testLibrary>::@class::B
    type: B<int>
  leftParenthesis: (
  rightParenthesis: )
  matchedValueType: A<int>
''');
  }

  test_class_generic_noTypeArguments_infer_partial_inference() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class B<T> {}
abstract class C<T, U extends Set<T>> extends B<T> {}

void f(B<int> b) {
  switch (b) {
    case C():
  }
}
''');

    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: C
    element: <testLibrary>::@class::C
    type: C<int, Set<int>>
  leftParenthesis: (
  rightParenthesis: )
  matchedValueType: B<int>
''');
  }

  test_class_generic_noTypeArguments_infer_useBounds() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T extends num> {}

void f(Object? x) {
  switch (x) {
    case A():
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@class::A
    type: A<num>
  leftParenthesis: (
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_class_generic_noTypeArguments_infer_viaTypeAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: L
    element: <testLibrary>::@typeAlias::L
    type: B<int, String>
      alias: <testLibrary>::@typeAlias::L
        typeArguments
          int
  leftParenthesis: (
  rightParenthesis: )
  matchedValueType: A<int, String>
''');
  }

  test_class_generic_withTypeArguments_hasName_variable_untyped() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A<T> {
  T get foo;
}

void f(x) {
  switch (x) {
    case A<int>(foo: var foo2):
//                       ^^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo2' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@class::A
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
        declaredFragment: isPublic foo2@90
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      element: SubstitutedGetterElementImpl
        baseElement: <testLibrary>::@class::A::@getter::foo
        substitution: {T: int}
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_class_notGeneric_hasName_constant() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@class::A
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
      element: <testLibrary>::@class::A::@getter::foo
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_class_notGeneric_hasName_extensionGetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@class::A
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
      element: <testLibrary>::@extension::E::@getter::foo
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_class_notGeneric_hasName_method() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  void foo();
}

void f(x) {
  switch (x) {
    case A(foo: var y):
//                  ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@class::A
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
        declaredFragment: isPublic y@83
          element: hasImplicitType isPublic
            type: void Function()
        matchedValueType: void Function()
      element: <testLibrary>::@class::A::@method::foo
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_class_notGeneric_hasName_method_ofExtension() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}

extension E on A {
  void foo() {}
}

void f(x) {
  switch (x) {
    case A(foo: var y):
//                  ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@class::A
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
        declaredFragment: isPublic y@97
          element: hasImplicitType isPublic
            type: void Function()
        matchedValueType: void Function()
      element: <testLibrary>::@extension::E::@method::foo
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_class_notGeneric_hasName_variable_untyped() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int get foo;
}

void f(x) {
  switch (x) {
    case A(foo: var foo2):
//                  ^^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo2' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@class::A
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
        declaredFragment: isPublic foo2@84
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      element: <testLibrary>::@class::A::@getter::foo
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_class_notGeneric_noName_constant() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int get foo;
}

void f(x) {
  switch (x) {
    case A(: 0):
//         ^^^
// [diag.missingNamedPatternFieldName] The getter name is not specified explicitly, and the pattern is not a variable.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@class::A
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
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_class_notGeneric_noName_variable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int get foo;
}

void f(x) {
  switch (x) {
    case A(: var foo):
//               ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@class::A
    type: A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: foo
        declaredFragment: isPublic foo@81
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      element: <testLibrary>::@class::A::@getter::foo
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_class_notGeneric_noName_variable_cast() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int? get foo;
}

void f(x) {
  switch (x) {
    case A(: var foo as int):
//               ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@class::A
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
          declaredFragment: isPublic foo@82
            element: hasImplicitType isPublic
              type: int
          matchedValueType: int
        asToken: as
        type: NamedType
          name: int
          element: dart:core::@class::int
          type: int
        matchedValueType: int?
      element: <testLibrary>::@class::A::@getter::foo
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_class_notGeneric_noName_variable_nullAssert() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int? get foo;
}

void f(x) {
  switch (x) {
    case A(: var foo!):
//               ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@class::A
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
          declaredFragment: isPublic foo@82
            element: hasImplicitType isPublic
              type: int
          matchedValueType: int
        operator: !
        matchedValueType: int?
      element: <testLibrary>::@class::A::@getter::foo
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_class_notGeneric_noName_variable_nullCheck() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int? get foo;
}

void f(x) {
  switch (x) {
    case A(: var foo?):
//               ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@class::A
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
          declaredFragment: isPublic foo@82
            element: hasImplicitType isPublic
              type: int
          matchedValueType: int
        operator: ?
        matchedValueType: int?
      element: <testLibrary>::@class::A::@getter::foo
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_class_notGeneric_noName_variable_parenthesis() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {
  int get foo;
}

void f(x) {
  switch (x) {
    case A(: (var foo)):
//                ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@class::A
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
          declaredFragment: isPublic foo@82
            element: hasImplicitType isPublic
              type: int
          matchedValueType: int
        rightParenthesis: )
        matchedValueType: int
      element: <testLibrary>::@class::A::@getter::foo
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_class_notGeneric_positionalField() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(Object? x) {
  if (x case Object(0)) {}
//                  ^
// [diag.positionalFieldInObjectPattern] Object patterns can only use named fields.
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: Object
    element: dart:core::@class::Object
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
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_class_notGeneric_unresolved_hasName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {}

void f(x) {
  switch (x) {
    case A(foo: 0):
//         ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type 'A'.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@class::A
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
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_class_notGeneric_unresolved_noName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
abstract class A {}

void f(x) {
  switch (x) {
    case A(: var foo):
//               ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type 'A'.
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@class::A
    type: A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: foo
        declaredFragment: isPublic foo@65
          element: hasImplicitType isPublic
            type: dynamic
        matchedValueType: dynamic
      element: <null>
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_extensionType_notGeneric_hasName_constant() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@extensionType::A
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
      element: <testLibrary>::@extensionType::A::@getter::foo
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_extensionType_notGeneric_noName_variable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  int get foo => 0;
}

void f(x) {
  switch (x) {
    case A(: final foo):
//                 ^^^
// [diag.unusedLocalVariable] The value of the local variable 'foo' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@extensionType::A
    type: A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        colon: :
      pattern: DeclaredVariablePattern
        keyword: final
        name: foo
        declaredFragment: isFinal isPublic foo@96
          element: hasImplicitType isFinal isPublic
            type: int
        matchedValueType: int
      element: <testLibrary>::@extensionType::A::@getter::foo
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_extensionType_notGeneric_unresolved_hasName() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}

void f(x) {
  switch (x) {
    case A(foo: 0):
//         ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type 'A'.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@extensionType::A
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
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_typeAlias_nullable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = int?;

void f(x) {
  switch (x) {
    case A(foo: 0):
//       ^
// [diag.uncheckedPropertyAccessOfNullableValue] The property 'foo' can't be unconditionally accessed because the receiver can be 'null'.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@typeAlias::A
    type: int?
      alias: <testLibrary>::@typeAlias::A
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
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_typedef_dynamic_hasName_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = dynamic;

void f(Object? x) {
  switch (x) {
    case A(foo: var y):
//                  ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@typeAlias::A
    type: dynamic
      alias: <testLibrary>::@typeAlias::A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredFragment: isPublic y@77
          element: hasImplicitType isPublic
            type: dynamic
              alias: <testLibrary>::@typeAlias::A
        matchedValueType: dynamic
          alias: <testLibrary>::@typeAlias::A
      element: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_typedef_functionType_generic_withTypeArguments_hasName_extensionGetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A<T> = T Function();

extension E on int Function() {
  int get foo => 0;
}

void f(Object? x) {
  switch (x) {
    case A<int>(foo: var y):
//                       ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          name: int
          element: dart:core::@class::int
          type: int
      rightBracket: >
    element: <testLibrary>::@typeAlias::A
    type: int Function()
      alias: <testLibrary>::@typeAlias::A
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
        declaredFragment: isPublic y@145
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      element: <testLibrary>::@extension::E::@getter::foo
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_typedef_functionType_notGeneric_hasName_extensionGetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = void Function();

extension E on void Function() {
  int get foo => 0;
}

void f(Object? x) {
  switch (x) {
    case A(foo: var y):
//                  ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@typeAlias::A
    type: void Function()
      alias: <testLibrary>::@typeAlias::A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredFragment: isPublic y@141
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      element: <testLibrary>::@extension::E::@getter::foo
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_typedef_functionType_notGeneric_hasName_hashCode() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = void Function();

void f(Object? x) {
  switch (x) {
    case A(hashCode: var y):
//                       ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@typeAlias::A
    type: void Function()
      alias: <testLibrary>::@typeAlias::A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: hashCode
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredFragment: isPublic y@90
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      element: dart:core::@class::Object::@getter::hashCode
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_typedef_functionType_notGeneric_hasName_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = void Function();

void f(Object? x) {
  switch (x) {
    case A(foo: var y):
//         ^^^
// [diag.undefinedGetter] The getter 'foo' isn't defined for the type 'A'.
//                  ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@typeAlias::A
    type: void Function()
      alias: <testLibrary>::@typeAlias::A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredFragment: isPublic y@85
          element: hasImplicitType isPublic
            type: dynamic
        matchedValueType: dynamic
      element: <null>
  rightParenthesis: )
  matchedValueType: Object?
''');
  }

  test_typedef_recordType_notGeneric_hasName_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = ({int foo});

void f(x) {
  switch (x) {
    case A(foo: var y):
//                  ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@typeAlias::A
    type: ({int foo})
      alias: <testLibrary>::@typeAlias::A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: foo
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredFragment: isPublic y@73
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      element: <null>
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_typedef_recordType_notGeneric_hasName_positional() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
typedef A = (int foo,);

void f(x) {
  switch (x) {
    case A($1: var y):
//                 ^
// [diag.unusedLocalVariable] The value of the local variable 'y' isn't used.
      break;
  }
}
''');
    var node = result.findNode.singleGuardedPattern.pattern;
    assertResolvedNodeText(node, r'''
ObjectPattern
  type: NamedType
    name: A
    element: <testLibrary>::@typeAlias::A
    type: (int,)
      alias: <testLibrary>::@typeAlias::A
  leftParenthesis: (
  fields
    PatternField
      name: PatternFieldName
        name: $1
        colon: :
      pattern: DeclaredVariablePattern
        keyword: var
        name: y
        declaredFragment: isPublic y@71
          element: hasImplicitType isPublic
            type: int
        matchedValueType: int
      element: <null>
  rightParenthesis: )
  matchedValueType: dynamic
''');
  }

  test_variableDeclaration_inferredType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f(A<int> x) {
  var A(foo: a) = x;
//           ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}

class A<T> {
  T get foo => throw 0;
}
''');
    var node = result.findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ObjectPattern
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A<int>
    leftParenthesis: (
    fields
      PatternField
        name: PatternFieldName
          name: foo
          colon: :
        pattern: DeclaredVariablePattern
          name: a
          declaredFragment: isPublic a@32
            element: hasImplicitType isPublic
              type: int
          matchedValueType: int
        element: SubstitutedGetterElementImpl
          baseElement: <testLibrary>::@class::A::@getter::foo
          substitution: {T: int}
    rightParenthesis: )
    matchedValueType: A<int>
  equals: =
  expression: SimpleIdentifier
    token: x
    element: <testLibrary>::@function::f::@formalParameter::x
    staticType: A<int>
  patternTypeSchema: A<dynamic>
''');
  }

  // TODO(scheglov): Remove `new` (everywhere), implement rewrite.
  test_variableDeclaration_typeSchema_withTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var A<int>(foo: a) = new A();
//                ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}

class A<T> {
  T get foo => throw 0;
}
''');
    var node = result.findNode.singlePatternVariableDeclaration;
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
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: <testLibrary>::@class::A
      type: A<int>
    leftParenthesis: (
    fields
      PatternField
        name: PatternFieldName
          name: foo
          colon: :
        pattern: DeclaredVariablePattern
          name: a
          declaredFragment: isPublic a@29
            element: hasImplicitType isPublic
              type: int
          matchedValueType: int
        element: SubstitutedGetterElementImpl
          baseElement: <testLibrary>::@class::A::@getter::foo
          substitution: {T: int}
    rightParenthesis: )
    matchedValueType: A<int>
  equals: =
  expression: InstanceCreationExpression
    keyword: new
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: <testLibrary>::@class::A
        type: A<int>
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A<int>
  patternTypeSchema: A<int>
''');
  }

  test_variableDeclaration_typeSchema_withVariableType() async {
    // `int a` does not propagate up, we get `A<dynamic>`
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  var A(foo: int a) = new A();
//               ^
// [diag.unusedLocalVariable] The value of the local variable 'a' isn't used.
}

class A<T> {
  T get foo => throw 0;
}
''');
    var node = result.findNode.singlePatternVariableDeclaration;
    assertResolvedNodeText(node, r'''
PatternVariableDeclaration
  keyword: var
  pattern: ObjectPattern
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
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
            element: dart:core::@class::int
            type: int
          name: a
          declaredFragment: isPublic a@28
            element: isPublic
              type: int
          matchedValueType: dynamic
        element: SubstitutedGetterElementImpl
          baseElement: <testLibrary>::@class::A::@getter::foo
          substitution: {T: dynamic}
    rightParenthesis: )
    matchedValueType: A<dynamic>
  equals: =
  expression: InstanceCreationExpression
    keyword: new
    constructorName: ConstructorName
      type: NamedType
        name: A
        element: <testLibrary>::@class::A
        type: A<dynamic>
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: dynamic}
    argumentList: ArgumentList
      leftParenthesis: (
      rightParenthesis: )
    staticType: A<dynamic>
  patternTypeSchema: A<dynamic>
''');
  }
}
