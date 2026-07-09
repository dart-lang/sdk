// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InstanceCreationExpressionResolutionTest);
    defineReflectiveTests(
      InstanceCreationExpressionResolutionTest_WithoutConstructorTearoffs,
    );
    defineReflectiveTests(
      InstanceCreationExpressionResolutionTest_WithoutPrivateNamedParameters,
    );
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InstanceCreationExpressionResolutionTest extends PubPackageResolutionTest
    with InstanceCreationTestCases {}

@reflectiveTest
class InstanceCreationExpressionResolutionTest_WithoutConstructorTearoffs
    extends PubPackageResolutionTest
    with WithoutConstructorTearoffsMixin {
  test_unnamedViaNew() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A(int a);
}

void f() {
  A.new(0);
//  ^^^
// [diag.experimentNotEnabled] This requires the 'constructor-tearoffs' language feature to be enabled.
}
''');

    // Resolution should continue even though the experiment is not enabled.
    var node = result.findNode.instanceCreation('A.new(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::A::@constructor::new
      staticType: null
    element: <testLibrary>::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }
}

@reflectiveTest
class InstanceCreationExpressionResolutionTest_WithoutPrivateNamedParameters
    extends PubPackageResolutionTest
    with WithoutPrivateNamedParametersMixin {
  test_preFeature() async {
    var result = await resolveTestCodeWithDiagnostics('''
class C {
  int? _x;
//     ^^
// [diag.unusedField] The value of the field '_x' isn't used.
  C({this._x});
//        ^^
// [diag.experimentNotEnabled] This requires the 'private-named-parameters' language feature to be enabled.
}

main() {
  C(x: 123);
//  ^
// [diag.undefinedNamedParameter] The named parameter 'x' isn't defined.
}
''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: C
      element: <testLibrary>::@class::C
      type: C
    element: <testLibrary>::@class::C::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NamedArgument
        name: x
        colon: :
        argumentExpression: IntegerLiteral
          literal: 123
          staticType: int
        correspondingParameter: <null>
    rightParenthesis: )
  staticType: C
''');
  }
}

mixin InstanceCreationTestCases on PubPackageResolutionTest {
  test_arguments_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int a, {required bool b, required double c});
}

void f() {
  A(0, b: true, c: 1.2);
}
''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A
    element: <testLibrary>::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        staticType: int
      NamedArgument
        name: b
        colon: :
        argumentExpression: BooleanLiteral
          literal: true
          staticType: bool
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::b
      NamedArgument
        name: c
        colon: :
        argumentExpression: DoubleLiteral
          literal: 1.2
          staticType: double
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::c
    rightParenthesis: )
  staticType: A
''');
  }

  test_class_generic_named_inferTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  A.named(T t);
}

void f() {
  A.named(0);
}
''');

    var node = result.findNode.instanceCreation('A.named(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: dynamic}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::t
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_class_generic_named_withTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  A.named();
}

void f() {
  A<int>.named();
}
''');

    var node = result.findNode.instanceCreation('A<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
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
    period: .
    name: SimpleIdentifier
      token: named
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_class_generic_unnamed_inferTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  A(T t);
}

void f() {
  A(0);
}
''');

    var node = result.findNode.instanceCreation('A(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
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
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::t
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_class_generic_unnamed_withTypeArguments() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {}

void f() {
  A<int>();
}
''');

    var node = result.findNode.instanceCreation('A<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
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
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_class_notGeneric_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  A.named(int a);
}

void f() {
  A.named(0);
}
''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      element: <testLibrary>::@class::A::@constructor::named
      staticType: null
    element: <testLibrary>::@class::A::@constructor::named
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@constructor::named::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_class_notGeneric_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  A(int a);
}

void f() {
  A(0);
}

''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A
    element: <testLibrary>::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_class_notGeneric_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}

void f() {
  new A.unresolved(0);
//      ^^^^^^^^^^
// [diag.newWithUndefinedConstructor] The class 'A' doesn't have a constructor named 'unresolved'.
}

''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: unresolved
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_demoteType() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  A(T t);
}

void f<S>(S s) {
  if (s is int) {
    A(s);
  }
}

''');

    var node = result.findNode.instanceCreation('A(s)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A<S>
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: S}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      SimpleIdentifier
        token: s
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::t
          substitution: {T: S}
        element: <testLibrary>::@function::f::@formalParameter::s
        staticType: S & int
    rightParenthesis: )
  staticType: A<S>
''');
  }

  test_error_newWithInvalidTypeParameters_implicitNew_inference_top() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
final foo = Map<int>();
//          ^^^^^^^^
// [diag.wrongNumberOfTypeArguments] The type 'Map' is declared with 2 type parameters, but 1 type arguments were given.
''');

    var node = result.findNode.instanceCreation('Map<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: Map
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: dart:core::@class::Map
      type: Map<dynamic, dynamic>
    element: SubstitutedConstructorElementImpl
      baseElement: dart:core::@class::Map::@constructor::new
      substitution: {K: dynamic, V: dynamic}
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: Map<dynamic, dynamic>
''');
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_explicitNew() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class Foo<X> {
  Foo.bar();
}

main() {
  new Foo.bar<int>();
//           ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'Foo.bar' doesn't have type parameters.
}
''');

    var node = result.findNode.instanceCreation('Foo.bar<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: Foo
      element: <testLibrary>::@class::Foo
      type: Foo<dynamic>
    period: .
    name: SimpleIdentifier
      token: bar
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::Foo::@constructor::bar
        substitution: {X: dynamic}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::Foo::@constructor::bar
      substitution: {X: dynamic}
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: Foo<dynamic>
''');
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_explicitNew_new() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class Foo<X> {
  Foo.new();
}

main() {
  new Foo.new<int>();
//           ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'Foo.new' doesn't have type parameters.
}
''');

    var node = result.findNode.instanceCreation('Foo.new<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: Foo
      element: <testLibrary>::@class::Foo
      type: Foo<dynamic>
    period: .
    name: SimpleIdentifier
      token: new
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::Foo::@constructor::new
        substitution: {X: dynamic}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::Foo::@constructor::new
      substitution: {X: dynamic}
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: Foo<dynamic>
''');
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_explicitNew_prefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class Foo<X> {
  Foo.bar();
}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;

main() {
  new p.Foo.bar<int>();
//          ^^^
// [diag.constructorWithTypeArguments] A constructor invocation can't have type arguments after the constructor name.
}
''');

    // TODO(brianwilkerson): Test this more carefully after we can re-write the
    // AST to reflect the expected structure.
    var node = result.findNode.instanceCreation('Foo.bar<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: p
        period: .
        element: <testLibraryFragment>::@prefix::p
      name: Foo
      element: package:test/a.dart::@class::Foo
      type: Foo<dynamic>
    period: .
    name: SimpleIdentifier
      token: bar
      element: SubstitutedConstructorElementImpl
        baseElement: package:test/a.dart::@class::Foo::@constructor::bar
        substitution: {X: dynamic}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: package:test/a.dart::@class::Foo::@constructor::bar
      substitution: {X: dynamic}
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: Foo<dynamic>
''');
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_implicitNew() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class Foo<X> {
  Foo.bar();
}

main() {
  Foo.bar<int>();
//       ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'Foo.bar' doesn't have type parameters.
}
''');

    var node = result.findNode.instanceCreation('Foo.bar<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: Foo
      element: <testLibrary>::@class::Foo
      type: Foo<dynamic>
    period: .
    name: SimpleIdentifier
      token: bar
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::Foo::@constructor::bar
        substitution: {X: dynamic}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::Foo::@constructor::bar
      substitution: {X: dynamic}
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::@class::int
        type: int
    rightBracket: >
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: Foo<dynamic>
''');
  }

  test_error_wrongNumberOfTypeArgumentsConstructor_implicitNew_prefix() async {
    newFile('$testPackageLibPath/a.dart', '''
class Foo<X> {
  Foo.bar();
}
''');
    var result = await resolveTestCodeWithDiagnostics('''
import 'a.dart' as p;

main() {
  p.Foo.bar<int>();
//         ^^^^^
// [diag.wrongNumberOfTypeArgumentsConstructor] The constructor 'p.Foo.bar' doesn't have type parameters.
}
''');

    var node = result.findNode.instanceCreation('Foo.bar<int>');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: p
        period: .
        element: <testLibraryFragment>::@prefix::p
      name: Foo
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: package:test/a.dart::@class::Foo
      type: Foo<int>
    period: .
    name: SimpleIdentifier
      token: bar
      element: SubstitutedConstructorElementImpl
        baseElement: package:test/a.dart::@class::Foo::@constructor::bar
        substitution: {X: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: package:test/a.dart::@class::Foo::@constructor::bar
      substitution: {X: int}
  argumentList: ArgumentList
    leftParenthesis: (
    rightParenthesis: )
  staticType: Foo<int>
''');
  }

  test_extensionType_generic_primary_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A<T>(T it) {}

void f() {
  A(0);
}
''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@extensionType::A
      type: A<int>
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@extensionType::A::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_extensionType_generic_secondary_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A<T>.named(T it) {
  A(this.it);
}

void f() {
  A(0);
}
''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@extensionType::A
      type: A<int>
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@extensionType::A::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_extensionType_notGeneric_primary_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A.named(int it) {}

void f() {
  A.named(0);
}
''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@extensionType::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      element: <testLibrary>::@extensionType::A::@constructor::named
      staticType: null
    element: <testLibrary>::@extensionType::A::@constructor::named
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_extensionType_notGeneric_primary_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}

void f() {
  A(0);
}
''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@extensionType::A
      type: A
    element: <testLibrary>::@extensionType::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_extensionType_notGeneric_secondary_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  A.named(this.it);
}

void f() {
  A.named(0);
}
''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@extensionType::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      element: <testLibrary>::@extensionType::A::@constructor::named
      staticType: null
    element: <testLibrary>::@extensionType::A::@constructor::named
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_extensionType_notGeneric_secondary_unnamed() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A.named(int it) {
  A(this.it);
}

void f() {
  A(0);
}
''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@extensionType::A
      type: A
    element: <testLibrary>::@extensionType::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_extensionType_notGeneric_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {}

void f() {
  new A.named(0);
//      ^^^^^
// [diag.newWithUndefinedConstructor] The class 'A' doesn't have a constructor named 'named'.
}
''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@extensionType::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_importPrefix() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as prefix;

void f() {
  new prefix(0);
//    ^^^^^^
// [diag.newWithNonType] The name 'prefix' isn't a class.
}

''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: prefix
      element: <testLibraryFragment>::@prefix::prefix
      type: InvalidType
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_importPrefix_class_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A.named(int a);
}
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

void f() {
  prefix.A.named(0);
}

''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element: <testLibraryFragment>::@prefix::prefix
      name: A
      element: package:test/a.dart::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: named
      element: package:test/a.dart::@class::A::@constructor::named
      staticType: null
    element: package:test/a.dart::@class::A::@constructor::named
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: package:test/a.dart::@class::A::@constructor::named::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_importPrefix_class_typeArguments_named() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  A.named(int a);
}
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

void f() {
  prefix.A<int>.named(0);
}

''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element: <testLibraryFragment>::@prefix::prefix
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: package:test/a.dart::@class::A
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      element: SubstitutedConstructorElementImpl
        baseElement: package:test/a.dart::@class::A::@constructor::named
        substitution: {T: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: package:test/a.dart::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: package:test/a.dart::@class::A::@constructor::named::@formalParameter::a
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_importPrefix_class_typeArguments_unnamed() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  A(int a);
}
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

void f() {
  prefix.A<int>(0);
}

''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element: <testLibraryFragment>::@prefix::prefix
      name: A
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            name: int
            element: dart:core::@class::int
            type: int
        rightBracket: >
      element: package:test/a.dart::@class::A
      type: A<int>
    element: SubstitutedConstructorElementImpl
      baseElement: package:test/a.dart::@class::A::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: package:test/a.dart::@class::A::@constructor::new::@formalParameter::a
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_importPrefix_class_unnamed() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  A(int a);
}
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

void f() {
  prefix.A(0);
}

''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element: <testLibraryFragment>::@prefix::prefix
      name: A
      element: package:test/a.dart::@class::A
      type: A
    element: package:test/a.dart::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: package:test/a.dart::@class::A::@constructor::new::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_importPrefix_class_unresolved() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

void f() {
  new prefix.A.foo(0);
//             ^^^
// [diag.newWithUndefinedConstructor] The class 'prefix.A' doesn't have a constructor named 'foo'.
}

''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element: <testLibraryFragment>::@prefix::prefix
      name: A
      element: package:test/a.dart::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_importPrefix_unresolved_identifier() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'dart:math' as prefix;

void f() {
  new prefix.Foo.bar(0);
//           ^^^
// [diag.newWithNonType] The name 'Foo' isn't a class.
}

''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: prefix
        period: .
        element: <testLibraryFragment>::@prefix::prefix
      name: Foo
      element: <null>
      type: InvalidType
    period: .
    name: SimpleIdentifier
      token: bar
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_namedArgument_anywhere() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {}
class B {}
class C {}
class D {}

class X {
  X(A a, B b, {C? c, D? d});
}

T g1<T>() => throw 0;
T g2<T>() => throw 0;
T g3<T>() => throw 0;
T g4<T>() => throw 0;

void f() {
  X(g1(), c: g3(), g2(), d: g4());
}
''');

    var node = result.findNode.instanceCreation('X(g');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: X
      element: <testLibrary>::@class::X
      type: X
    element: <testLibrary>::@class::X::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      MethodInvocation
        methodName: SimpleIdentifier
          token: g1
          element: <testLibrary>::@function::g1
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        correspondingParameter: <testLibrary>::@class::X::@constructor::new::@formalParameter::a
        staticInvokeType: A Function()
        staticType: A
        typeArgumentTypes
          A
      NamedArgument
        name: c
        colon: :
        argumentExpression: MethodInvocation
          methodName: SimpleIdentifier
            token: g3
            element: <testLibrary>::@function::g3
            staticType: T Function<T>()
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          staticInvokeType: C? Function()
          staticType: C?
          typeArgumentTypes
            C?
        correspondingParameter: <testLibrary>::@class::X::@constructor::new::@formalParameter::c
      MethodInvocation
        methodName: SimpleIdentifier
          token: g2
          element: <testLibrary>::@function::g2
          staticType: T Function<T>()
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        correspondingParameter: <testLibrary>::@class::X::@constructor::new::@formalParameter::b
        staticInvokeType: B Function()
        staticType: B
        typeArgumentTypes
          B
      NamedArgument
        name: d
        colon: :
        argumentExpression: MethodInvocation
          methodName: SimpleIdentifier
            token: g4
            element: <testLibrary>::@function::g4
            staticType: T Function<T>()
          argumentList: ArgumentList
            leftParenthesis: (
            rightParenthesis: )
          staticInvokeType: D? Function()
          staticType: D?
          typeArgumentTypes
            D?
        correspondingParameter: <testLibrary>::@class::X::@constructor::new::@formalParameter::d
    rightParenthesis: )
  staticType: X
''');
  }

  test_privateNamedParameter_privateNamedArgument() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int? _x;
//     ^^
// [diag.unusedField] The value of the field '_x' isn't used.
  C({this._x});
}

main() {
  C(_x: 123);
//  ^^
// [diag.useOfPrivateParameterName] The named parameter '_x' should use the corresponding public name 'x' at the callsite.
}
''');

    var node = result.findNode.instanceCreation('C(_x');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: C
      element: <testLibrary>::@class::C
      type: C
    element: <testLibrary>::@class::C::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NamedArgument
        name: _x
        colon: :
        argumentExpression: IntegerLiteral
          literal: 123
          staticType: int
        correspondingParameter: <null>
    rightParenthesis: )
  staticType: C
''');
  }

  test_privateNamedParameter_publicNamedArgument() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class C {
  int? _x;
//     ^^
// [diag.unusedField] The value of the field '_x' isn't used.
  C({this._x});
}

main() {
  C(x: 123);
}
''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: C
      element: <testLibrary>::@class::C
      type: C
    element: <testLibrary>::@class::C::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      NamedArgument
        name: x
        colon: :
        argumentExpression: IntegerLiteral
          literal: 123
          staticType: int
        correspondingParameter: <testLibrary>::@class::C::@constructor::new::@formalParameter::x
    rightParenthesis: )
  staticType: C
''');
  }

  test_typeAlias_generic_class_generic_named_infer_all() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  A.named(T t);
}

typedef B<U> = A<U>;

void f() {
  B.named(0);
}
''');

    var node = result.findNode.instanceCreation('B.named(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: B
      element: <testLibrary>::@typeAlias::B
      type: A<int>
    period: .
    name: SimpleIdentifier
      token: named
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: dynamic}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::t
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_typeAlias_generic_class_generic_named_infer_partial() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T, U> {
  A.named(T t, U u);
}

typedef B<V> = A<V, String>;

void f() {
  B.named(0, '');
}
''');

    var node = result.findNode.instanceCreation('B.named(0, ');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: B
      element: <testLibrary>::@typeAlias::B
      type: A<int, String>
    period: .
    name: SimpleIdentifier
      token: named
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: dynamic, U: String}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int, U: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::t
          substitution: {T: int, U: String}
        staticType: int
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  staticType: A<int, String>
''');
  }

  test_typeAlias_generic_class_generic_unnamed_infer_all() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  A(T t);
}

typedef B<U> = A<U>;

void f() {
  B(0);
}
''');

    var node = result.findNode.instanceCreation('B(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: B
      element: <testLibrary>::@typeAlias::B
      type: A<int>
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::t
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  staticType: A<int>
''');
  }

  test_typeAlias_generic_class_generic_unnamed_infer_partial() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T, U> {
  A(T t, U u);
}

typedef B<V> = A<V, String>;

void f() {
  B(0, '');
}
''');

    var node = result.findNode.instanceCreation('B(0, ');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: B
      element: <testLibrary>::@typeAlias::B
      type: A<int, String>
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int, U: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::t
          substitution: {T: int, U: String}
        staticType: int
      SimpleStringLiteral
        literal: ''
    rightParenthesis: )
  staticType: A<int, String>
''');
  }

  test_typeAlias_notGeneric_class_generic_named_argumentTypeMismatch() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  A.named(T t);
}

typedef B = A<String>;

void f() {
  B.named(0);
//        ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
}
''');

    var node = result.findNode.instanceCreation('B.named(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: B
      element: <testLibrary>::@typeAlias::B
      type: A<String>
    period: .
    name: SimpleIdentifier
      token: named
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: String}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::t
          substitution: {T: String}
        staticType: int
    rightParenthesis: )
  staticType: A<String>
''');
  }

  test_typeAlias_notGeneric_class_generic_unnamed_argumentTypeMismatch() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  A(T t);
}

typedef B = A<String>;

void f() {
  B(0);
//  ^
// [diag.argumentTypeNotAssignable] The argument type 'int' can't be assigned to the parameter type 'String'.
}
''');

    var node = result.findNode.instanceCreation('B(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: B
      element: <testLibrary>::@typeAlias::B
      type: A<String>
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: String}
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::t
          substitution: {T: String}
        staticType: int
    rightParenthesis: )
  staticType: A<String>
''');
  }

  test_unnamed_declaredNew() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A.new(int a);
}

void f() {
  A(0);
}

''');

    var node = result.findNode.instanceCreation('A(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A
    element: <testLibrary>::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_unnamedViaNew_declaredNew() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A.new(int a);
}

void f() {
  A.new(0);
}

''');

    var node = result.findNode.instanceCreation('A.new(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::A::@constructor::new
      staticType: null
    element: <testLibrary>::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_unnamedViaNew_declaredUnnamed() async {
    var result = await resolveTestCodeWithDiagnostics('''
class A {
  A(int a);
}

void f() {
  A.new(0);
}

''');

    var node = result.findNode.instanceCreation('A.new(0)');
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  constructorName: ConstructorName
    type: NamedType
      name: A
      element: <testLibrary>::@class::A
      type: A
    period: .
    name: SimpleIdentifier
      token: new
      element: <testLibrary>::@class::A::@constructor::new
      staticType: null
    element: <testLibrary>::@class::A::@constructor::new
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        staticType: int
    rightParenthesis: )
  staticType: A
''');
  }

  test_unresolved() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  new Unresolved(0);
//    ^^^^^^^^^^
// [diag.newWithNonType] The name 'Unresolved' isn't a class.
}

''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      name: Unresolved
      element: <null>
      type: InvalidType
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_unresolved_identifier() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  new Unresolved.named(0);
//    ^^^^^^^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'Unresolved'.
}

''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: Unresolved
        period: .
        element: <null>
      name: named
      element: <null>
      type: InvalidType
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: InvalidType
''');
  }

  test_unresolved_identifier_identifier() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
void f() {
  new unresolved.Foo.bar(0);
//    ^^^^^^^^^^^^^^
// [diag.undefinedIdentifier] Undefined name 'unresolved'.
}

''');

    var node = result.findNode.singleInstanceCreationExpression;
    assertResolvedNodeText(node, r'''
InstanceCreationExpression
  keyword: new
  constructorName: ConstructorName
    type: NamedType
      importPrefix: ImportPrefixReference
        name: unresolved
        period: .
        element: <null>
      name: Foo
      element: <null>
      type: InvalidType
    period: .
    name: SimpleIdentifier
      token: bar
      element: <null>
      staticType: null
    element: <null>
  argumentList: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  staticType: InvalidType
''');
  }
}
