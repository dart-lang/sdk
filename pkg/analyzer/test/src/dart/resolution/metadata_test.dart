// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/test_utilities/find_element.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MetadataResolutionTest);
  });
}

@reflectiveTest
class MetadataResolutionTest extends PubPackageResolutionTest {
  ImportFindElement get import_a {
    return findElement.importFind('package:test/a.dart');
  }

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
    staticElement: <testLibraryFragment>::@getter::a
    element: <testLibraryFragment>::@getter::a#element
    staticType: null
  element: <testLibraryFragment>::@getter::a
  element2: <testLibraryFragment>::@getter::a#element
''');
    _assertAnnotationValueText(annotation, '''
int 42
  variable: <testLibraryFragment>::@topLevelVariable::a
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
    staticElement: <testLibraryFragment>::@enum::E::@getter::v
    element: <testLibraryFragment>::@enum::E::@getter::v#element
    staticType: null
  element: <testLibraryFragment>::@enum::E::@getter::v
  element2: <testLibraryFragment>::@enum::E::@getter::v#element
''');

    _assertAnnotationValueText(annotation, '''
E
  _name: String v
  index: int 0
  variable: <testLibraryFragment>::@enum::E::@field::v
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
    staticElement: <testLibraryFragment>::@class::A
    element: <testLibraryFragment>::@class::A#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      InstanceCreationExpression
        constructorName: ConstructorName
          type: NamedType
            name: A
            element: <testLibraryFragment>::@class::A
            element2: <testLibraryFragment>::@class::A#element
            type: A
          staticElement: <testLibraryFragment>::@class::A::@constructor::new
          element: <testLibraryFragment>::@class::A::@constructor::new#element
        argumentList: ArgumentList
          leftParenthesis: (
          arguments
            IntegerLiteral
              literal: 0
              parameter: <testLibraryFragment>::@class::A::@constructor::new::@parameter::f
              staticType: int
          rightParenthesis: )
        parameter: <testLibraryFragment>::@class::A::@constructor::new::@parameter::f
        staticType: A
    rightParenthesis: )
  element: <testLibraryFragment>::@class::A::@constructor::new
  element2: <testLibraryFragment>::@class::A::@constructor::new#element
''');
    _assertAnnotationValueText(annotation, r'''
A
  f: A
    f: int 0
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
    staticElement: <testLibraryFragment>::@class::A
    element: <testLibraryFragment>::@class::A#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 3
        parameter: <testLibraryFragment>::@class::A::@constructor::new::@parameter::a
        staticType: int
    rightParenthesis: )
  element: <testLibraryFragment>::@class::A::@constructor::new
  element2: <testLibraryFragment>::@class::A::@constructor::new#element
''');

    var localVariable = findElement.localVar('x');
    var annotationOnElement = localVariable.metadata.single;
    _assertElementAnnotationValueText(annotationOnElement, '''
A
  a: int 3
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
    await assertErrorsInCode(r'''
@foo
part 'a.dart';
const foo = 42;
''', [
      error(CompileTimeErrorCode.URI_DOES_NOT_EXIST, 10, 8),
    ]);

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
    staticElement: <testLibraryFragment>::@class::A
    element: <testLibraryFragment>::@class::A#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <testLibraryFragment>::@class::A::@constructor::new::@parameter::f
        staticType: int
    rightParenthesis: )
  element: <testLibraryFragment>::@class::A::@constructor::new
  element2: <testLibraryFragment>::@class::A::@constructor::new#element
''');
    _assertAnnotationValueText(node, r'''
A
  f: int 0
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
    staticElement: <testLibraryFragment>::@class::A
    element: <testLibraryFragment>::@class::A#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 0
        parameter: <testLibraryFragment>::@class::A::@constructor::new::@parameter::f
        staticType: int
    rightParenthesis: )
  element: <testLibraryFragment>::@class::A::@constructor::new
  element2: <testLibraryFragment>::@class::A::@constructor::new#element
''');
    _assertAnnotationValueText(node, r'''
A
  f: int 0
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
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      staticElement: <testLibraryFragment>::@class::A::@constructor::named
      element: <testLibraryFragment>::@class::A::@constructor::named#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@constructor::named
    element: <testLibraryFragment>::@class::A::@constructor::named#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: <testLibraryFragment>::@class::A::@constructor::named::@parameter::f
        staticType: int
    rightParenthesis: )
  element: <testLibraryFragment>::@class::A::@constructor::named
  element2: <testLibraryFragment>::@class::A::@constructor::named#element
''');
    _assertAnnotationValueText(annotation, '''
A
  f: int 42
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
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      staticElement: <testLibraryFragment>::@class::A::@constructor::named
      element: <testLibraryFragment>::@class::A::@constructor::named#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@constructor::named
    element: <testLibraryFragment>::@class::A::@constructor::named#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: <testLibraryFragment>::@class::A::@constructor::named::@parameter::f
        staticType: int
    rightParenthesis: )
  element: <testLibraryFragment>::@class::A::@constructor::named
  element2: <testLibraryFragment>::@class::A::@constructor::named#element
''');

    _assertAnnotationValueText(node, r'''
A
  f: int 42
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
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@getter::foo
      element: <testLibraryFragment>::@class::A::@getter::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
    staticType: null
  element: <testLibraryFragment>::@class::A::@getter::foo
  element2: <testLibraryFragment>::@class::A::@getter::foo#element
''');
    _assertAnnotationValueText(annotation, '''
int 42
  variable: <testLibraryFragment>::@class::A::@field::foo
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
    staticElement: <testLibraryFragment>::@class::A
    element: <testLibraryFragment>::@class::A#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: <testLibraryFragment>::@class::A::@constructor::new::@parameter::f
        staticType: int
    rightParenthesis: )
  element: <testLibraryFragment>::@class::A::@constructor::new
  element2: <testLibraryFragment>::@class::A::@constructor::new#element
''');

    _assertAnnotationValueText(node, r'''
A
  f: int 42
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
    staticElement: <testLibraryFragment>::@class::D
    element: <testLibraryFragment>::@class::D#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      InstanceCreationExpression
        keyword: const
        constructorName: ConstructorName
          type: NamedType
            name: C
            element: <testLibraryFragment>::@class::C
            element2: <testLibraryFragment>::@class::C#element
            type: C
          staticElement: <testLibraryFragment>::@class::C::@constructor::new
          element: <testLibraryFragment>::@class::C::@constructor::new#element
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        parameter: <testLibraryFragment>::@class::D::@constructor::new::@parameter::c
        staticType: C
    rightParenthesis: )
  element: <testLibraryFragment>::@class::D::@constructor::new
  element2: <testLibraryFragment>::@class::D::@constructor::new#element
''');

    _assertAnnotationValueText(node, r'''
D
  c: C
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
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::named
        substitution: {T: Object?}
      element: <testLibraryFragment>::@class::A::@constructor::named#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::named
      substitution: {T: Object?}
    element: <testLibraryFragment>::@class::A::@constructor::named#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      ListLiteral
        leftBracket: [
        rightBracket: ]
        parameter: FieldFormalParameterMember
          base: <testLibraryFragment>::@class::A::@constructor::named::@parameter::f
          substitution: {T: Object?}
        staticType: List<List<Object?>>
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::A::@constructor::named
    substitution: {T: Object?}
  element2: <testLibraryFragment>::@class::A::@constructor::named#element
''');
    _assertAnnotationValueText(annotation, '''
A<Object?>
  f: List
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
    staticElement: <testLibraryFragment>::@class::A
    element: <testLibraryFragment>::@class::A#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      ListLiteral
        leftBracket: [
        rightBracket: ]
        parameter: FieldFormalParameterMember
          base: <testLibraryFragment>::@class::A::@constructor::new::@parameter::f
          substitution: {T: Object?}
        staticType: List<List<Object?>>
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::A::@constructor::new
    substitution: {T: Object?}
  element2: <testLibraryFragment>::@class::A::@constructor::new#element
''');
    _assertAnnotationValueText(annotation, r'''
A<Object?>
  f: List
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
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::named
        substitution: {T: int}
      element: <testLibraryFragment>::@class::A::@constructor::named#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::named
      substitution: {T: int}
    element: <testLibraryFragment>::@class::A::@constructor::named#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: <testLibraryFragment>::@class::A::@constructor::named::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::A::@constructor::named
    substitution: {T: int}
  element2: <testLibraryFragment>::@class::A::@constructor::named#element
''');
    _assertAnnotationValueText(annotation, '''
A<int>
  f: int 42
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
    staticElement: <testLibraryFragment>::@class::A
    element: <testLibraryFragment>::@class::A#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: <testLibraryFragment>::@class::A::@constructor::new::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::A::@constructor::new
    substitution: {T: int}
  element2: <testLibraryFragment>::@class::A::@constructor::new#element
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
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
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@getter::foo
      element: <testLibraryFragment>::@class::A::@getter::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
    staticType: null
  element: <testLibraryFragment>::@class::A::@getter::foo
  element2: <testLibraryFragment>::@class::A::@getter::foo#element
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
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::named
        substitution: {T: dynamic}
      element: <testLibraryFragment>::@class::A::@constructor::named#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::named
      substitution: {T: dynamic}
    element: <testLibraryFragment>::@class::A::@constructor::named#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: <testLibraryFragment>::@class::A::@constructor::named::@parameter::f
          substitution: {T: dynamic}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::A::@constructor::named
    substitution: {T: dynamic}
  element2: <testLibraryFragment>::@class::A::@constructor::named#element
''');
    _assertAnnotationValueText(annotation, '''
A<dynamic>
  f: int 42
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
      staticElement: <testLibraryFragment>::@class::A
      element: <testLibraryFragment>::@class::A#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@getter::foo
      element: <testLibraryFragment>::@class::A::@getter::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
    staticType: null
  element: <testLibraryFragment>::@class::A::@getter::foo
  element2: <testLibraryFragment>::@class::A::@getter::foo#element
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
    staticElement: <testLibraryFragment>::@class::A
    element: <testLibraryFragment>::@class::A#element
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  period: .
  constructorName: SimpleIdentifier
    token: named
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::named
      substitution: {T: int}
    element: <testLibraryFragment>::@class::A::@constructor::named#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: <testLibraryFragment>::@class::A::@constructor::named::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::A::@constructor::named
    substitution: {T: int}
  element2: <testLibraryFragment>::@class::A::@constructor::named#element
''');
    _assertAnnotationValueText(annotation, '''
A<int>
  f: int 42
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
    staticElement: <testLibraryFragment>::@class::A
    element: <testLibraryFragment>::@class::A#element
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: <testLibraryFragment>::@class::A::@constructor::new::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::A::@constructor::new
    substitution: {T: int}
  element2: <testLibraryFragment>::@class::A::@constructor::new#element
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
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
    staticElement: <testLibraryFragment>::@class::A
    element: <testLibraryFragment>::@class::A#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: <testLibraryFragment>::@class::A::@constructor::new::@parameter::f
          substitution: {T: dynamic}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::A::@constructor::new
    substitution: {T: dynamic}
  element2: <testLibraryFragment>::@class::A::@constructor::new#element
''');
    _assertAnnotationValueText(annotation, r'''
A<dynamic>
  f: int 42
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
    staticElement: <testLibraryFragment>::@class::B
    element: <testLibraryFragment>::@class::B#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: ParameterMember
          base: <testLibraryFragment>::@class::B::@constructor::new::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::B::@constructor::new
    substitution: {T: int}
  element2: <testLibraryFragment>::@class::B::@constructor::new#element
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
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
    staticElement: <testLibraryFragment>::@class::B
    element: <testLibraryFragment>::@class::B#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: ParameterMember
          base: <testLibraryFragment>::@class::B::@constructor::new::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::B::@constructor::new
    substitution: {T: int}
  element2: <testLibraryFragment>::@class::B::@constructor::new#element
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
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
    staticElement: <testLibraryFragment>::@class::B
    element: <testLibraryFragment>::@class::B#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: ParameterMember
          base: <testLibraryFragment>::@class::B::@constructor::new::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::B::@constructor::new
    substitution: {T: int}
  element2: <testLibraryFragment>::@class::B::@constructor::new#element
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
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
    staticElement: <testLibraryFragment>::@class::B
    element: <testLibraryFragment>::@class::B#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: ParameterMember
          base: <testLibraryFragment>::@class::B::@constructor::new::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::B::@constructor::new
    substitution: {T: int}
  element2: <testLibraryFragment>::@class::B::@constructor::new#element
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
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
    staticElement: <testLibraryFragment>::@class::B
    element: <testLibraryFragment>::@class::B#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: ParameterMember
          base: <testLibraryFragment>::@class::B::@constructor::new::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::B::@constructor::new
    substitution: {T: int}
  element2: <testLibraryFragment>::@class::B::@constructor::new#element
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
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
    staticElement: <testLibraryFragment>::@class::B
    element: <testLibraryFragment>::@class::B#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: ParameterMember
          base: <testLibraryFragment>::@class::B::@constructor::new::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::B::@constructor::new
    substitution: {T: int}
  element2: <testLibraryFragment>::@class::B::@constructor::new#element
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
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
    staticElement: <testLibraryFragment>::@class::B
    element: <testLibraryFragment>::@class::B#element
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: ParameterMember
          base: <testLibraryFragment>::@class::B::@constructor::new::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::B::@constructor::new
    substitution: {T: int}
  element2: <testLibraryFragment>::@class::B::@constructor::new#element
''');
    _assertAnnotationValueText(annotation, r'''
B<int>
  (super): A<int>
    f: int 42
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

    var classC = findNode.namedType('C c').element!;
    var annotation = classC.metadata.single;
    _assertElementAnnotationValueText(annotation, r'''
B
  a: A
    f: int 42
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

    var classB = findNode.namedType('B b').element!;
    var annotation = classB.metadata.single;
    _assertElementAnnotationValueText(annotation, r'''
A
  f: int 42
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

    var classB = findNode.namedType('B b').element!;
    var annotation = classB.metadata.single;
    _assertElementAnnotationValueText(annotation, r'''
A
  f: int 42
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
      staticElement: <testLibraryFragment>::@prefix::prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: A
      staticElement: package:test/a.dart::<fragment>::@class::A
      element: package:test/a.dart::<fragment>::@class::A#element
      staticType: null
    staticElement: package:test/a.dart::<fragment>::@class::A
    element: package:test/a.dart::<fragment>::@class::A#element
    staticType: null
  period: .
  constructorName: SimpleIdentifier
    token: named
    staticElement: package:test/a.dart::<fragment>::@class::A::@constructor::named
    element: package:test/a.dart::<fragment>::@class::A::@constructor::named#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: package:test/a.dart::<fragment>::@class::A::@constructor::named::@parameter::f
        staticType: int
    rightParenthesis: )
  element: package:test/a.dart::<fragment>::@class::A::@constructor::named
  element2: package:test/a.dart::<fragment>::@class::A::@constructor::named#element
''');

    _assertAnnotationValueText(node, '''
A
  f: int 42
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
      staticElement: <testLibraryFragment>::@prefix::prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: A
      staticElement: package:test/a.dart::<fragment>::@class::A
      element: package:test/a.dart::<fragment>::@class::A#element
      staticType: null
    staticElement: package:test/a.dart::<fragment>::@class::A
    element: package:test/a.dart::<fragment>::@class::A#element
    staticType: null
  period: .
  constructorName: SimpleIdentifier
    token: foo
    staticElement: package:test/a.dart::<fragment>::@class::A::@getter::foo
    element: package:test/a.dart::<fragment>::@class::A::@getter::foo#element
    staticType: null
  element: package:test/a.dart::<fragment>::@class::A::@getter::foo
  element2: package:test/a.dart::<fragment>::@class::A::@getter::foo#element
''');

    _assertAnnotationValueText(node, '''
int 42
  variable: package:test/a.dart::<fragment>::@class::A::@field::foo
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
      staticElement: <testLibraryFragment>::@prefix::prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: A
      staticElement: package:test/a.dart::<fragment>::@class::A
      element: package:test/a.dart::<fragment>::@class::A#element
      staticType: null
    staticElement: package:test/a.dart::<fragment>::@class::A
    element: package:test/a.dart::<fragment>::@class::A#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: package:test/a.dart::<fragment>::@class::A::@constructor::new::@parameter::f
        staticType: int
    rightParenthesis: )
  element: package:test/a.dart::<fragment>::@class::A::@constructor::new
  element2: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
''');

    _assertAnnotationValueText(node, '''
A
  f: int 42
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
      staticElement: <testLibraryFragment>::@prefix::prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: package:test/a.dart::<fragment>::@getter::foo
      element: package:test/a.dart::<fragment>::@getter::foo#element
      staticType: null
    staticElement: package:test/a.dart::<fragment>::@getter::foo
    element: package:test/a.dart::<fragment>::@getter::foo#element
    staticType: null
  element: package:test/a.dart::<fragment>::@getter::foo
  element2: package:test/a.dart::<fragment>::@getter::foo#element
''');

    _assertAnnotationValueText(node, '''
int 42
  variable: package:test/a.dart::<fragment>::@topLevelVariable::foo
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
      staticElement: <testLibraryFragment>::@prefix::prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: B
      staticElement: package:test/a.dart::<fragment>::@typeAlias::B
      element: package:test/a.dart::<fragment>::@typeAlias::B#element
      staticType: null
    staticElement: package:test/a.dart::<fragment>::@typeAlias::B
    element: package:test/a.dart::<fragment>::@typeAlias::B#element
    staticType: null
  period: .
  constructorName: SimpleIdentifier
    token: foo
    staticElement: package:test/a.dart::<fragment>::@class::A::@getter::foo
    element: package:test/a.dart::<fragment>::@class::A::@getter::foo#element
    staticType: null
  element: package:test/a.dart::<fragment>::@class::A::@getter::foo
  element2: package:test/a.dart::<fragment>::@class::A::@getter::foo#element
''');
    _assertAnnotationValueText(annotation, '''
int 42
  variable: package:test/a.dart::<fragment>::@class::A::@field::foo
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
      staticElement: <testLibraryFragment>::@prefix::prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: B
      staticElement: package:test/a.dart::<fragment>::@typeAlias::B
      element: package:test/a.dart::<fragment>::@typeAlias::B#element
      staticType: null
    staticElement: package:test/a.dart::<fragment>::@typeAlias::B
    element: package:test/a.dart::<fragment>::@typeAlias::B#element
    staticType: null
  period: .
  constructorName: SimpleIdentifier
    token: named
    staticElement: ConstructorMember
      base: package:test/a.dart::<fragment>::@class::A::@constructor::named
      substitution: {T: int}
    element: package:test/a.dart::<fragment>::@class::A::@constructor::named#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: package:test/a.dart::<fragment>::@class::A::@constructor::named::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: package:test/a.dart::<fragment>::@class::A::@constructor::named
    substitution: {T: int}
  element2: package:test/a.dart::<fragment>::@class::A::@constructor::named#element
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
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
      staticElement: <testLibraryFragment>::@prefix::prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: B
      staticElement: package:test/a.dart::<fragment>::@typeAlias::B
      element: package:test/a.dart::<fragment>::@typeAlias::B#element
      staticType: null
    staticElement: package:test/a.dart::<fragment>::@typeAlias::B
    element: package:test/a.dart::<fragment>::@typeAlias::B#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: package:test/a.dart::<fragment>::@class::A::@constructor::new::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: package:test/a.dart::<fragment>::@class::A::@constructor::new
    substitution: {T: int}
  element2: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
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
      staticElement: <testLibraryFragment>::@prefix::prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: B
      staticElement: package:test/a.dart::<fragment>::@typeAlias::B
      element: package:test/a.dart::<fragment>::@typeAlias::B#element
      staticType: null
    staticElement: package:test/a.dart::<fragment>::@typeAlias::B
    element: package:test/a.dart::<fragment>::@typeAlias::B#element
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  period: .
  constructorName: SimpleIdentifier
    token: named
    staticElement: ConstructorMember
      base: package:test/a.dart::<fragment>::@class::A::@constructor::named
      substitution: {T: int}
    element: package:test/a.dart::<fragment>::@class::A::@constructor::named#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: package:test/a.dart::<fragment>::@class::A::@constructor::named::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: package:test/a.dart::<fragment>::@class::A::@constructor::named
    substitution: {T: int}
  element2: package:test/a.dart::<fragment>::@class::A::@constructor::named#element
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
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
      staticElement: <testLibraryFragment>::@prefix::prefix
      element: <testLibraryFragment>::@prefix2::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: B
      staticElement: package:test/a.dart::<fragment>::@typeAlias::B
      element: package:test/a.dart::<fragment>::@typeAlias::B#element
      staticType: null
    staticElement: package:test/a.dart::<fragment>::@typeAlias::B
    element: package:test/a.dart::<fragment>::@typeAlias::B#element
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: package:test/a.dart::<fragment>::@class::A::@constructor::new::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: package:test/a.dart::<fragment>::@class::A::@constructor::new
    substitution: {T: int}
  element2: package:test/a.dart::<fragment>::@class::A::@constructor::new#element
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
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
      staticElement: <testLibraryFragment>::@typeAlias::B
      element: <testLibraryFragment>::@typeAlias::B#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      staticElement: <testLibraryFragment>::@class::A::@getter::foo
      element: <testLibraryFragment>::@class::A::@getter::foo#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@getter::foo
    element: <testLibraryFragment>::@class::A::@getter::foo#element
    staticType: null
  element: <testLibraryFragment>::@class::A::@getter::foo
  element2: <testLibraryFragment>::@class::A::@getter::foo#element
''');
    _assertAnnotationValueText(annotation, '''
int 42
  variable: <testLibraryFragment>::@class::A::@field::foo
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
    staticElement: <testLibraryFragment>::@typeAlias::B
    element: <testLibraryFragment>::@typeAlias::B#element
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  period: .
  constructorName: SimpleIdentifier
    token: named
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::named
      substitution: {T: int, U: double}
    element: <testLibraryFragment>::@class::A::@constructor::named#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: <testLibraryFragment>::@class::A::@constructor::named::@parameter::t
          substitution: {T: int, U: double}
        staticType: int
      DoubleLiteral
        literal: 1.2
        parameter: FieldFormalParameterMember
          base: <testLibraryFragment>::@class::A::@constructor::named::@parameter::u
          substitution: {T: int, U: double}
        staticType: double
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::A::@constructor::named
    substitution: {T: int, U: double}
  element2: <testLibraryFragment>::@class::A::@constructor::named#element
''');
    _assertAnnotationValueText(annotation, r'''
A<int, double>
  t: int 42
  u: double 1.2
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
    staticElement: <testLibraryFragment>::@typeAlias::B
    element: <testLibraryFragment>::@typeAlias::B#element
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: <testLibraryFragment>::@class::A::@constructor::new::@parameter::t
          substitution: {T: int, U: double}
        staticType: int
      DoubleLiteral
        literal: 1.2
        parameter: FieldFormalParameterMember
          base: <testLibraryFragment>::@class::A::@constructor::new::@parameter::u
          substitution: {T: int, U: double}
        staticType: double
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::A::@constructor::new
    substitution: {T: int, U: double}
  element2: <testLibraryFragment>::@class::A::@constructor::new#element
''');
    _assertAnnotationValueText(annotation, r'''
A<int, double>
  t: int 42
  u: double 1.2
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
      staticElement: <testLibraryFragment>::@typeAlias::B
      element: <testLibraryFragment>::@typeAlias::B#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::named
        substitution: {T: int}
      element: <testLibraryFragment>::@class::A::@constructor::named#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::named
      substitution: {T: int}
    element: <testLibraryFragment>::@class::A::@constructor::named#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: <testLibraryFragment>::@class::A::@constructor::named::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::A::@constructor::named
    substitution: {T: int}
  element2: <testLibraryFragment>::@class::A::@constructor::named#element
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
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
    staticElement: <testLibraryFragment>::@typeAlias::B
    element: <testLibraryFragment>::@typeAlias::B#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: <testLibraryFragment>::@class::A::@constructor::new::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::A::@constructor::new
    substitution: {T: int}
  element2: <testLibraryFragment>::@class::A::@constructor::new#element
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
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
    staticElement: <testLibraryFragment>::@typeAlias::B
    element: <testLibraryFragment>::@typeAlias::B#element
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  period: .
  constructorName: SimpleIdentifier
    token: named
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::named
      substitution: {T: int}
    element: <testLibraryFragment>::@class::A::@constructor::named#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: <testLibraryFragment>::@class::A::@constructor::named::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::A::@constructor::named
    substitution: {T: int}
  element2: <testLibraryFragment>::@class::A::@constructor::named#element
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
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
    staticElement: <testLibraryFragment>::@typeAlias::B
    element: <testLibraryFragment>::@typeAlias::B#element
    staticType: null
  typeArguments: TypeArgumentList
    leftBracket: <
    arguments
      NamedType
        name: int
        element: dart:core::<fragment>::@class::int
        element2: dart:core::<fragment>::@class::int#element
        type: int
    rightBracket: >
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: <testLibraryFragment>::@class::A::@constructor::new::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::A::@constructor::new
    substitution: {T: int}
  element2: <testLibraryFragment>::@class::A::@constructor::new#element
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
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
      staticElement: <testLibraryFragment>::@typeAlias::B
      element: <testLibraryFragment>::@typeAlias::B#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      staticElement: ConstructorMember
        base: <testLibraryFragment>::@class::A::@constructor::named
        substitution: {T: int}
      element: <testLibraryFragment>::@class::A::@constructor::named#element
      staticType: null
    staticElement: ConstructorMember
      base: <testLibraryFragment>::@class::A::@constructor::named
      substitution: {T: int}
    element: <testLibraryFragment>::@class::A::@constructor::named#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: <testLibraryFragment>::@class::A::@constructor::named::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::A::@constructor::named
    substitution: {T: int}
  element2: <testLibraryFragment>::@class::A::@constructor::named#element
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
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
    staticElement: <testLibraryFragment>::@typeAlias::B
    element: <testLibraryFragment>::@typeAlias::B#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: FieldFormalParameterMember
          base: <testLibraryFragment>::@class::A::@constructor::new::@parameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: ConstructorMember
    base: <testLibraryFragment>::@class::A::@constructor::new
    substitution: {T: int}
  element2: <testLibraryFragment>::@class::A::@constructor::new#element
''');
    _assertAnnotationValueText(annotation, r'''
A<int>
  f: int 42
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
      staticElement: <testLibraryFragment>::@typeAlias::B
      element: <testLibraryFragment>::@typeAlias::B#element
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: named
      staticElement: <testLibraryFragment>::@class::A::@constructor::named
      element: <testLibraryFragment>::@class::A::@constructor::named#element
      staticType: null
    staticElement: <testLibraryFragment>::@class::A::@constructor::named
    element: <testLibraryFragment>::@class::A::@constructor::named#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: <testLibraryFragment>::@class::A::@constructor::named::@parameter::f
        staticType: int
    rightParenthesis: )
  element: <testLibraryFragment>::@class::A::@constructor::named
  element2: <testLibraryFragment>::@class::A::@constructor::named#element
''');
    _assertAnnotationValueText(annotation, r'''
A
  f: int 42
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
    staticElement: <testLibraryFragment>::@typeAlias::B
    element: <testLibraryFragment>::@typeAlias::B#element
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        parameter: <testLibraryFragment>::@class::A::@constructor::new::@parameter::f
        staticType: int
    rightParenthesis: )
  element: <testLibraryFragment>::@class::A::@constructor::new
  element2: <testLibraryFragment>::@class::A::@constructor::new#element
''');
    _assertAnnotationValueText(annotation, r'''
A
  f: int 42
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
    staticElement: <testLibraryFragment>::@getter::foo
    element: <testLibraryFragment>::@getter::foo#element
    staticType: null
  element: <testLibraryFragment>::@getter::foo
  element2: <testLibraryFragment>::@getter::foo#element
''');

    var element = node.elementAnnotation!;
    _assertElementAnnotationValueText(element, r'''
int 42
  variable: <testLibraryFragment>::@topLevelVariable::foo
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
