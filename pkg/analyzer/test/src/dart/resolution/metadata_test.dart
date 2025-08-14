// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/utilities/package_config_file_builder.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MetadataResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class MetadataResolutionTest extends PubPackageResolutionTest {
  test_at_genericFunctionType_formalParameter() async {
    await assertNoErrorsInCode(r'''
const a = 42;
List<void Function(@a int b)> f() => [];
''');

    var annotation = findNode.annotation('@a');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: a
    element: <testLibrary>::@getter::a
    staticType: null
  element2: <testLibrary>::@getter::a
''');
    _assertAnnotationValueText(annotation, '''
int 42
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_location_class_classDeclaration() async {
    await assertNoErrorsInCode(r'''
const foo = 42;

@foo
class A {}
''');

    _assertAtFoo42();
  }

  test_location_class_constructor_formalParameter() async {
    await assertNoErrorsInCode(r'''
const foo = 42;

class A {
  A.named(@foo int a);
}
''');

    _assertAtFoo42();
  }

  test_location_class_constructorDeclaration() async {
    await assertNoErrorsInCode(r'''
const foo = 42;

class A {
  @foo
  A.named();
}
''');

    _assertAtFoo42();
  }

  test_location_class_fieldDeclaration() async {
    await assertNoErrorsInCode(r'''
const foo = 42;

class A {
  @foo
  final bar = 0;
}
''');

    _assertAtFoo42();
  }

  test_location_enumConstant() async {
    await assertNoErrorsInCode(r'''
enum E {
  @v
  v;
}
''');

    var annotation = findNode.annotation('@v');
    assertResolvedNodeText(annotation, '''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: v
    element: <testLibrary>::@enum::E::@getter::v
    staticType: null
  element2: <testLibrary>::@enum::E::@getter::v
''');

    _assertAnnotationValueText(annotation, '''
E
  _name: String v
  index: int 0
  constructorInvocation
    constructor: <testLibrary>::@enum::E::@constructor::new
  variable: <testLibrary>::@enum::E::@field::v
''');
  }

  test_location_extensionType_representation() async {
    await assertNoErrorsInCode(r'''
const foo = 42;

extension type A(@foo int it) {}
''');

    _assertAtFoo42();
  }

  test_location_fieldFormal() async {
    await assertNoErrorsInCode(r'''
class A {
  final Object f;
  const A(this.f);
}

class B {
  final int f;
  B({@A( A(0) ) required this.f});
}
''');
    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@class::A
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      InstanceCreationExpression
        constructorName: ConstructorName
          type: NamedType
            name: A
            element2: <testLibrary>::@class::A
            type: A
          element: <testLibrary>::@class::A::@constructor::new
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            IntegerLiteral
              literal: 0
              correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
              staticType: int
          rightParenthesis: )
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
        staticType: A
    rightParenthesis: )
  element2: <testLibrary>::@class::A::@constructor::new
''');
    _assertAnnotationValueText(annotation, r'''
A
  f: A
    f: int 0
    constructorInvocation
      constructor: <testLibrary>::@class::A::@constructor::new
      positionalArguments
        0: int 0
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: A
        f: int 0
        constructorInvocation
          constructor: <testLibrary>::@class::A::@constructor::new
          positionalArguments
            0: int 0
''');
  }

  test_location_forEachPartsWithDeclaration() async {
    await resolveTestCode(r'''
void f() {
  for (var @foo x = 0;;) {}
}
''');
    // This is invalid code.
    // No checks, as long as it does not crash.
  }

  test_location_libraryDirective() async {
    await assertNoErrorsInCode(r'''
@foo
library my;
const foo = 42;
''');

    _assertAtFoo42();
  }

  test_location_libraryExportDirective() async {
    newFile('$testPackageLibPath/a.dart', '');

    await assertNoErrorsInCode(r'''
@foo
export 'a.dart';
const foo = 42;
''');

    _assertAtFoo42();
  }

  test_location_libraryImportDirective() async {
    newFile('$testPackageLibPath/a.dart', '');

    await assertNoErrorsInCode(r'''
@foo
import 'a.dart'; // ignore:unused_import
const foo = 42;
''');

    _assertAtFoo42();
  }

  test_location_localVariable() async {
    await assertNoErrorsInCode(r'''
class A {
  final int a;
  const A(this.a);
}

void f() {
  @A(3)
  int? x;
  print(x);
}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, '''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@class::A
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 3
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::a
        staticType: int
    rightParenthesis: )
  element2: <testLibrary>::@class::A::@constructor::new
''');

    var localVariable = findElement2.localVar('x');
    var annotationOnElement = localVariable.metadata.annotations.first;
    _assertElementAnnotationValueText(annotationOnElement, '''
A
  a: int 3
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 3
''');
  }

  test_location_localVariableDeclaration() async {
    await resolveTestCode(r'''
void f() {
  var @foo x;
}
''');
    // This is invalid code.
    // No checks, as long as it does not crash.
  }

  test_location_methodDeclaration() async {
    await assertNoErrorsInCode(r'''
const foo = 42;

class A {
  @foo
  void bar() {}
}
''');

    _assertAtFoo42();
  }

  test_location_partDirective() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    await assertNoErrorsInCode(r'''
@foo
part 'a.dart';
const foo = 42;
''');

    _assertAtFoo42();
  }

  test_location_partDirective_fileDoesNotExist() async {
    await assertErrorsInCode(
      r'''
@foo
part 'a.dart';
const foo = 42;
''',
      [error(CompileTimeErrorCode.uriDoesNotExist, 10, 8)],
    );

    _assertAtFoo42();
  }

  test_location_partOfDirective() async {
    newFile('$testPackageLibPath/test.dart', r'''
part 'a.dart';
const foo = 42;
''');

    var a = newFile('$testPackageLibPath/a.dart', r'''
@foo
part of 'test.dart';
''');

    await resolveFile2(a);
    assertNoErrorsInResult();

    _assertAtFoo42();
  }

  test_location_recordTypeAnnotation_named() async {
    await assertNoErrorsInCode(r'''
class A {
  final int f;
  const A(this.f);
}

({@A(0) int f1, String f2}) f() => throw 0;
''');
    var node = findNode.annotation('@A');
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@class::A
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
        staticType: int
    rightParenthesis: )
  element2: <testLibrary>::@class::A::@constructor::new
''');
    _assertAnnotationValueText(node, r'''
A
  f: int 0
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 0
''');
  }

  test_location_recordTypeAnnotation_positional() async {
    await assertNoErrorsInCode(r'''
class A {
  final int f;
  const A(this.f);
}

(int, @A(0) String) f() => throw 0;
''');
    var node = findNode.annotation('@A');
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@class::A
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
        staticType: int
    rightParenthesis: )
  element2: <testLibrary>::@class::A::@constructor::new
''');
    _assertAnnotationValueText(node, r'''
A
  f: int 0
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 0
''');
  }

  test_location_topLevelFunctionDeclaration() async {
    await assertNoErrorsInCode(r'''
const foo = 42;

@foo
void bar() {}
''');

    _assertAtFoo42();
  }

  test_location_topLevelVariableDeclaration() async {
    await assertNoErrorsInCode(r'''
const foo = 42;

@foo
final bar = 0;
''');

    _assertAtFoo42();
  }

  test_value_class_inference_namedConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  final int f;
  const A.named(this.f);
}

@A.named(42)
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      element: <testLibrary>::@class::A::@constructor::named
      staticType: null
    element: <testLibrary>::@class::A::@constructor::named
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: <testLibrary>::@class::A::@constructor::named::@formalParameter::f
        staticType: int
    rightParenthesis: )
  element2: <testLibrary>::@class::A::@constructor::named
''');
    _assertAnnotationValueText(annotation, '''
A
  f: int 42
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::named
    positionalArguments
      0: int 42
''');
  }

  test_value_class_namedConstructor() async {
    await assertNoErrorsInCode(r'''
 class A {
  final int f;
  const A.named(this.f);
}

@A.named(42)
void f() {}
''');

    var node = findNode.singleAnnotation;
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      element: <testLibrary>::@class::A::@constructor::named
      staticType: null
    element: <testLibrary>::@class::A::@constructor::named
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: <testLibrary>::@class::A::@constructor::named::@formalParameter::f
        staticType: int
    rightParenthesis: )
  element2: <testLibrary>::@class::A::@constructor::named
''');

    _assertAnnotationValueText(node, r'''
A
  f: int 42
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::named
    positionalArguments
      0: int 42
''');
  }

  test_value_class_staticConstField() async {
    await assertNoErrorsInCode(r'''
class A {
  static const int foo = 42;
}

@A.foo
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: null
    element: <testLibrary>::@class::A::@getter::foo
    staticType: null
  element2: <testLibrary>::@class::A::@getter::foo
''');
    _assertAnnotationValueText(annotation, '''
int 42
  variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_value_class_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  final int f;
  const A(this.f);
}

@A(42)
void f() {}
''');

    var node = findNode.singleAnnotation;
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@class::A
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
        staticType: int
    rightParenthesis: )
  element2: <testLibrary>::@class::A::@constructor::new
''');

    _assertAnnotationValueText(node, r'''
A
  f: int 42
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 42
''');
  }

  test_value_class_unnamedConstructor_withNestedConstructorInvocation() async {
    await assertNoErrorsInCode(r'''
class C {
  const C();
}

class D {
  final C c;
  const D(this.c);
}

@D(const C())
void f() {}
''');

    var node = findNode.singleAnnotation;
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: D
    element: <testLibrary>::@class::D
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      InstanceCreationExpression
        keyword: const
        constructorName: ConstructorName
          type: NamedType
            name: C
            element2: <testLibrary>::@class::C
            type: C
          element: <testLibrary>::@class::C::@constructor::new
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        correspondingParameter: <testLibrary>::@class::D::@constructor::new::@formalParameter::c
        staticType: C
    rightParenthesis: )
  element2: <testLibrary>::@class::D::@constructor::new
''');

    _assertAnnotationValueText(node, r'''
D
  c: C
    constructorInvocation
      constructor: <testLibrary>::@class::C::@constructor::new
  constructorInvocation
    constructor: <testLibrary>::@class::D::@constructor::new
    positionalArguments
      0: C
        constructorInvocation
          constructor: <testLibrary>::@class::C::@constructor::new
''');
  }

  test_value_extensionType_namedConstructor() async {
    await assertNoErrorsInCode(r'''
extension type const A.named(int it) {}

@A.named(42)
void f() {}
''');

    var node = findNode.singleAnnotation;
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@extensionType::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      element: <testLibrary>::@extensionType::A::@constructor::named
      staticType: null
    element: <testLibrary>::@extensionType::A::@constructor::named
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: <testLibrary>::@extensionType::A::@constructor::named::@formalParameter::it
        staticType: int
    rightParenthesis: )
  element2: <testLibrary>::@extensionType::A::@constructor::named
''');

    _assertAnnotationValueText(node, r'''
int 42
''');
  }

  test_value_extensionType_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
extension type const A(int it) {}

@A(42)
void f() {}
''');

    var node = findNode.singleAnnotation;
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@extensionType::A
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: <testLibrary>::@extensionType::A::@constructor::new::@formalParameter::it
        staticType: int
    rightParenthesis: )
  element2: <testLibrary>::@extensionType::A::@constructor::new
''');

    _assertAnnotationValueText(node, r'''
int 42
''');
  }

  test_value_genericClass_downwards_inference_namedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final List<List<T>> f;
  const A.named(this.f);
}

@A.named([])
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: Object?}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: Object?}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      ListLiteral
        leftBracket: [
        rightBracket: ]
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::f
          substitution: {T: Object?}
        staticType: List<List<Object?>>
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::A::@constructor::named
    substitution: {T: Object?}
''');
    _assertAnnotationValueText(annotation, '''
A<Object?>
  f: List
    elementType: List<Object?>
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: Object?}
    positionalArguments
      0: List
        elementType: List<Object?>
''');
  }

  test_value_genericClass_downwards_inference_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
 class A<T> {
  final List<List<T>> f;
  const A(this.f);
}

@A([])
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@class::A
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      ListLiteral
        leftBracket: [
        rightBracket: ]
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
          substitution: {T: Object?}
        staticType: List<List<Object?>>
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::A::@constructor::new
    substitution: {T: Object?}
''');
    _assertAnnotationValueText(annotation, r'''
A<Object?>
  f: List
    elementType: List<Object?>
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: Object?}
    positionalArguments
      0: List
        elementType: List<Object?>
''');
  }

  test_value_genericClass_inference_namedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final T f;
  const A.named(this.f);
}

@A.named(42)
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: int}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::A::@constructor::named
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, '''
A<int>
  f: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericClass_inference_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

@A(42)
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@class::A
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::A::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericClass_instanceGetter() async {
    await resolveTestCode(r'''
class A<T> {
  T get foo {}
}

@A.foo
void f() {}
''');

    assertResolvedNodeText(findNode.annotation('@A'), r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: null
    element: <testLibrary>::@class::A::@getter::foo
    staticType: null
  element2: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_value_genericClass_namedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final int f;
  const A.named(this.f);
}

@A.named(42)
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: dynamic}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: dynamic}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::f
          substitution: {T: dynamic}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::A::@constructor::named
    substitution: {T: dynamic}
''');
    _assertAnnotationValueText(annotation, '''
A<dynamic>
  f: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: dynamic}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericClass_staticGetter() async {
    await resolveTestCode(r'''
class A<T> {
  static T get foo {}
}

@A.foo
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: A
      element: <testLibrary>::@class::A
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: null
    element: <testLibrary>::@class::A::@getter::foo
    staticType: null
  element2: <testLibrary>::@class::A::@getter::foo
''');
    _assertAnnotationValueText(annotation, '''
<null>
''');
  }

  test_value_genericClass_typeArguments_namedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final T f;
  const A.named(this.f);
}

@A<int>.named(42)
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@class::A
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::A::@constructor::named
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, '''
A<int>
  f: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericClass_typeArguments_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

@A<int>(42)
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@class::A
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::A::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericClass_unnamedConstructor_noGenericMetadata() async {
    writeTestPackageConfig(PackageConfigFileBuilder(), languageVersion: '2.12');
    await assertNoErrorsInCode(r'''
class A<T> {
  final T f;
  const A(this.f);
}

@A(42)
void f() {}
''');

    var annotation = findNode.annotation('@A');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: A
    element: <testLibrary>::@class::A
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
          substitution: {T: dynamic}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::A::@constructor::new
    substitution: {T: dynamic}
''');
    _assertAnnotationValueText(annotation, r'''
A<dynamic>
  f: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: dynamic}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericMixinApplication_inference_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

mixin M {}

class B<T> = A<T> with M;

@B(42)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    element: <testLibrary>::@class::B
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::B::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::B::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
    constructorInvocation
      constructor: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      positionalArguments
        0: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericMixinApplication_inference_unnamedConstructor_classTypeAlias() async {
    await assertNoErrorsInCode(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

mixin M {}

class B<T> = A<T> with M;

@B(42)
class C<T> = D with E;

class D {}
mixin E {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    element: <testLibrary>::@class::B
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::B::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::B::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
    constructorInvocation
      constructor: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      positionalArguments
        0: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericMixinApplication_inference_unnamedConstructor_functionTypeAlias() async {
    await assertNoErrorsInCode(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

mixin M {}

class B<T> = A<T> with M;

@B(42)
typedef T F<T>();
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    element: <testLibrary>::@class::B
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::B::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::B::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
    constructorInvocation
      constructor: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      positionalArguments
        0: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericMixinApplication_inference_unnamedConstructor_functionTypedFormalParameter() async {
    await assertNoErrorsInCode(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

mixin M {}

class B<T> = A<T> with M;

f(@B(42) g()) {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    element: <testLibrary>::@class::B
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::B::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::B::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
    constructorInvocation
      constructor: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      positionalArguments
        0: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericMixinApplication_inference_unnamedConstructor_genericTypeAlias() async {
    await assertNoErrorsInCode(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

mixin M {}

class B<T> = A<T> with M;

@B(42)
typedef F = void Function();
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    element: <testLibrary>::@class::B
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::B::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::B::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
    constructorInvocation
      constructor: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      positionalArguments
        0: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericMixinApplication_inference_unnamedConstructor_methodDeclaration() async {
    await assertNoErrorsInCode(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

mixin M {}

class B<T> = A<T> with M;

class C {
  @B(42)
  m() {}
}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    element: <testLibrary>::@class::B
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::B::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::B::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
    constructorInvocation
      constructor: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      positionalArguments
        0: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericMixinApplication_typeArguments_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

mixin M {}

class B<T> = A<T> with M;

@B<int>(42)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    element: <testLibrary>::@class::B
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: ParameterMember
          baseElement: <testLibrary>::@class::B::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::B::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
    constructorInvocation
      constructor: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      positionalArguments
        0: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_otherLibrary_implicitConst() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final int f;
  const A(this.f);
}

class B {
  final A a;
  const B(this.a);
}

@B( A(42) )
class C {}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart';

void f(C c) {}
''');

    var classC = findNode.namedType('C c').element as ClassElement;
    var annotation = classC.metadata.annotations.first;
    _assertElementAnnotationValueText(annotation, r'''
B
  a: A
    f: int 42
    constructorInvocation
      constructor: package:test/a.dart::@class::A::@constructor::new
      positionalArguments
        0: int 42
  constructorInvocation
    constructor: package:test/a.dart::@class::B::@constructor::new
    positionalArguments
      0: A
        f: int 42
        constructorInvocation
          constructor: package:test/a.dart::@class::A::@constructor::new
          positionalArguments
            0: int 42
''');
  }

  test_value_otherLibrary_namedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final int f;
  const A.named(this.f);
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

@A.named(42)
class B {}
''');

    await assertNoErrorsInCode(r'''
import 'b.dart';

void f(B b) {}
''');

    var classB = findNode.namedType('B b').element! as ClassElement;
    var annotation = classB.metadata.annotations.first;
    _assertElementAnnotationValueText(annotation, r'''
A
  f: int 42
  constructorInvocation
    constructor: package:test/a.dart::@class::A::@constructor::named
    positionalArguments
      0: int 42
''');
  }

  test_value_otherLibrary_unnamedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  final int f;
  const A(this.f);
}
''');

    newFile('$testPackageLibPath/b.dart', r'''
import 'a.dart';

@A(42)
class B {}
''');

    await assertNoErrorsInCode(r'''
import 'b.dart';

void f(B b) {}
''');

    var classB = findNode.namedType('B b').element as ClassElement;
    var annotation = classB.metadata.annotations.first;
    _assertElementAnnotationValueText(annotation, r'''
A
  f: int 42
  constructorInvocation
    constructor: package:test/a.dart::@class::A::@constructor::new
    positionalArguments
      0: int 42
''');
  }

  test_value_prefix_class_namedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
 class A {
  final int f;
  const A.named(this.f);
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

@prefix.A.named(42)
void f() {}
''');

    var node = findNode.singleAnnotation;
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: A
      element: package:test/a.dart::@class::A
      staticType: null
    element: package:test/a.dart::@class::A
    staticType: null
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: package:test/a.dart::@class::A::@constructor::named
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: package:test/a.dart::@class::A::@constructor::named::@formalParameter::f
        staticType: int
    rightParenthesis: )
  element2: package:test/a.dart::@class::A::@constructor::named
''');

    _assertAnnotationValueText(node, '''
A
  f: int 42
  constructorInvocation
    constructor: package:test/a.dart::@class::A::@constructor::named
    positionalArguments
      0: int 42
''');
  }

  test_value_prefix_class_staticConstField() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static const int foo = 42;
}
''');
    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

@prefix.A.foo
void f() {}
''');

    var node = findNode.singleAnnotation;
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: A
      element: package:test/a.dart::@class::A
      staticType: null
    element: package:test/a.dart::@class::A
    staticType: null
  period: .
  constructorName: SimpleIdentifier
    token: foo
    element: package:test/a.dart::@class::A::@getter::foo
    staticType: null
  element2: package:test/a.dart::@class::A::@getter::foo
''');

    _assertAnnotationValueText(node, '''
int 42
  variable: package:test/a.dart::@class::A::@field::foo
''');
  }

  test_value_prefix_class_unnamedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
 class A {
  final int f;
  const A(this.f);
}
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

@prefix.A(42)
void f() {}
''');

    var node = findNode.singleAnnotation;
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: A
      element: package:test/a.dart::@class::A
      staticType: null
    element: package:test/a.dart::@class::A
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: package:test/a.dart::@class::A::@constructor::new::@formalParameter::f
        staticType: int
    rightParenthesis: )
  element2: package:test/a.dart::@class::A::@constructor::new
''');

    _assertAnnotationValueText(node, '''
A
  f: int 42
  constructorInvocation
    constructor: package:test/a.dart::@class::A::@constructor::new
    positionalArguments
      0: int 42
''');
  }

  test_value_prefix_topLevelVariable() async {
    newFile('$testPackageLibPath/a.dart', r'''
const foo = 42;
''');

    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

@prefix.foo
void f() {}
''');

    var node = findNode.singleAnnotation;
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: package:test/a.dart::@getter::foo
      staticType: null
    element: package:test/a.dart::@getter::foo
    staticType: null
  element2: package:test/a.dart::@getter::foo
''');

    _assertAnnotationValueText(node, '''
int 42
  variable: package:test/a.dart::@topLevelVariable::foo
''');
  }

  test_value_prefix_typeAlias_class_staticConstField() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {
  static const int foo = 42;
}

typedef B = A;
''');
    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

@prefix.B.foo
void f() {}
''');

    var annotation = findNode.annotation('@prefix.B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: B
      element: package:test/a.dart::@typeAlias::B
      staticType: null
    element: package:test/a.dart::@typeAlias::B
    staticType: null
  period: .
  constructorName: SimpleIdentifier
    token: foo
    element: package:test/a.dart::@class::A::@getter::foo
    staticType: null
  element2: package:test/a.dart::@class::A::@getter::foo
''');
    _assertAnnotationValueText(annotation, '''
int 42
  variable: package:test/a.dart::@class::A::@field::foo
''');
  }

  test_value_prefix_typeAlias_generic_class_generic_all_inference_namedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  final T f;
  const A.named(this.f);
}

typedef B<U> = A<U>;
''');
    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

@prefix.B.named(42)
void f() {}
''');

    var annotation = findNode.annotation('@prefix.B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: B
      element: package:test/a.dart::@typeAlias::B
      staticType: null
    element: package:test/a.dart::@typeAlias::B
    staticType: null
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: ConstructorMember
      baseElement: package:test/a.dart::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: FieldFormalParameterMember
          baseElement: package:test/a.dart::@class::A::@constructor::named::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: package:test/a.dart::@class::A::@constructor::named
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: package:test/a.dart::@class::A::@constructor::named
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_prefix_typeAlias_generic_class_generic_all_inference_unnamedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  final T f;
  const A(this.f);
}

typedef B<U> = A<U>;
''');
    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

@prefix.B(42)
void f() {}
''');

    var annotation = findNode.annotation('@prefix.B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: B
      element: package:test/a.dart::@typeAlias::B
      staticType: null
    element: package:test/a.dart::@typeAlias::B
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: FieldFormalParameterMember
          baseElement: package:test/a.dart::@class::A::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: package:test/a.dart::@class::A::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: package:test/a.dart::@class::A::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_prefix_typeAlias_generic_class_generic_all_typeArguments_namedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  final T f;
  const A.named(this.f);
}

typedef B<U> = A<U>;
''');
    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

@prefix.B<int>.named(42)
void f() {}
''');

    var annotation = findNode.annotation('@prefix.B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: B
      element: package:test/a.dart::@typeAlias::B
      staticType: null
    element: package:test/a.dart::@typeAlias::B
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: ConstructorMember
      baseElement: package:test/a.dart::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: FieldFormalParameterMember
          baseElement: package:test/a.dart::@class::A::@constructor::named::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: package:test/a.dart::@class::A::@constructor::named
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: package:test/a.dart::@class::A::@constructor::named
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_prefix_typeAlias_generic_class_generic_all_typeArguments_unnamedConstructor() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A<T> {
  final T f;
  const A(this.f);
}

typedef B<U> = A<U>;
''');
    await assertNoErrorsInCode(r'''
import 'a.dart' as prefix;

@prefix.B<int>(42)
void f() {}
''');

    var annotation = findNode.annotation('@prefix.B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: B
      element: package:test/a.dart::@typeAlias::B
      staticType: null
    element: package:test/a.dart::@typeAlias::B
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: FieldFormalParameterMember
          baseElement: package:test/a.dart::@class::A::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: package:test/a.dart::@class::A::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: package:test/a.dart::@class::A::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_topLevelVariableDeclaration() async {
    await assertNoErrorsInCode(r'''
const foo = 42;

@foo
void f() {}
''');

    _assertAtFoo42();
  }

  test_value_typeAlias_class_staticConstField() async {
    await assertNoErrorsInCode(r'''
class A {
  static const int foo = 42;
}

typedef B = A;

@B.foo
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: B
      element: <testLibrary>::@typeAlias::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: null
    element: <testLibrary>::@class::A::@getter::foo
    staticType: null
  element2: <testLibrary>::@class::A::@getter::foo
''');
    _assertAnnotationValueText(annotation, '''
int 42
  variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_value_typeAlias_generic_class_generic_1of2_typeArguments_namedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  final T t;
  final U u;
  const A.named(this.t, this.u);
}

typedef B<T> = A<T, double>;

@B<int>.named(42, 1.2)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    element: <testLibrary>::@typeAlias::B
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int, U: double}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::t
          substitution: {T: int, U: double}
        staticType: int
      DoubleLiteral
        literal: 1.2
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::u
          substitution: {T: int, U: double}
        staticType: double
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::A::@constructor::named
    substitution: {T: int, U: double}
''');
    _assertAnnotationValueText(annotation, r'''
A<int, double>
  t: int 42
  u: double 1.2
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int, U: double}
    positionalArguments
      0: int 42
      1: double 1.2
''');
  }

  test_value_typeAlias_generic_class_generic_1of2_typeArguments_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T, U> {
  final T t;
  final U u;
  const A(this.t, this.u);
}

typedef B<T> = A<T, double>;

@B<int>(42, 1.2)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    element: <testLibrary>::@typeAlias::B
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::t
          substitution: {T: int, U: double}
        staticType: int
      DoubleLiteral
        literal: 1.2
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::u
          substitution: {T: int, U: double}
        staticType: double
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::A::@constructor::new
    substitution: {T: int, U: double}
''');
    _assertAnnotationValueText(annotation, r'''
A<int, double>
  t: int 42
  u: double 1.2
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int, U: double}
    positionalArguments
      0: int 42
      1: double 1.2
''');
  }

  test_value_typeAlias_generic_class_generic_all_inference_namedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final T f;
  const A.named(this.f);
}

typedef B<U> = A<U>;

@B.named(42)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: B
      element: <testLibrary>::@typeAlias::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: int}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::A::@constructor::named
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_typeAlias_generic_class_generic_all_inference_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final T f;
  const A(this.f);
}

typedef B<U> = A<U>;

@B(42)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    element: <testLibrary>::@typeAlias::B
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::A::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_typeAlias_generic_class_generic_all_typeArguments_namedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final T f;
  const A.named(this.f);
}

typedef B<U> = A<U>;

@B<int>.named(42)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    element: <testLibrary>::@typeAlias::B
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::A::@constructor::named
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_typeAlias_generic_class_generic_all_typeArguments_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final T f;
  const A(this.f);
}

typedef B<U> = A<U>;

@B<int>(42)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    element: <testLibrary>::@typeAlias::B
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element2: dart:core::@class::int
        type: int
    rightBracket: >
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::A::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_typeAlias_notGeneric_class_generic_namedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final T f;
  const A.named(this.f);
}

typedef B = A<int>;

@B.named(42)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: B
      element: <testLibrary>::@typeAlias::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      element: ConstructorMember
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: int}
      staticType: null
    element: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::A::@constructor::named
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_typeAlias_notGeneric_class_generic_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
class A<T> {
  final T f;
  const A(this.f);
}

typedef B = A<int>;

@B(42)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    element: <testLibrary>::@typeAlias::B
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: FieldFormalParameterMember
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element2: ConstructorMember
    baseElement: <testLibrary>::@class::A::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: ConstructorMember
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_typeAlias_notGeneric_class_notGeneric_namedConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  final int f;
  const A.named(this.f);
}

typedef B = A;

@B.named(42)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: B
      element: <testLibrary>::@typeAlias::B
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      element: <testLibrary>::@class::A::@constructor::named
      staticType: null
    element: <testLibrary>::@class::A::@constructor::named
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: <testLibrary>::@class::A::@constructor::named::@formalParameter::f
        staticType: int
    rightParenthesis: )
  element2: <testLibrary>::@class::A::@constructor::named
''');
    _assertAnnotationValueText(annotation, r'''
A
  f: int 42
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::named
    positionalArguments
      0: int 42
''');
  }

  test_value_typeAlias_notGeneric_class_notGeneric_unnamedConstructor() async {
    await assertNoErrorsInCode(r'''
class A {
  final int f;
  const A(this.f);
}

typedef B = A;

@B(42)
void f() {}
''');

    var annotation = findNode.annotation('@B');
    assertResolvedNodeText(annotation, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: B
    element: <testLibrary>::@typeAlias::B
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
        staticType: int
    rightParenthesis: )
  element2: <testLibrary>::@class::A::@constructor::new
''');
    _assertAnnotationValueText(annotation, r'''
A
  f: int 42
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::new
    positionalArguments
      0: int 42
''');
  }

  void _assertAnnotationValueText(Annotation annotation, String expected) {
    var elementAnnotation = annotation.elementAnnotation!;
    _assertElementAnnotationValueText(elementAnnotation, expected);
  }

  void _assertAtFoo42() {
    var node = findNode.annotation('@foo');
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: foo
    element: <testLibrary>::@getter::foo
    staticType: null
  element2: <testLibrary>::@getter::foo
''');

    var element = node.elementAnnotation!;
    _assertElementAnnotationValueText(element, r'''
int 42
  variable: <testLibrary>::@topLevelVariable::foo
''');
  }

  void _assertElementAnnotationValueText(
    ElementAnnotation annotation,
    String expected,
  ) {
    var value = annotation.computeConstantValue();
    assertDartObjectText(value, expected);
  }
}
