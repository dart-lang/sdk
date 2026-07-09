// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer_testing/package_config_file_builder.dart';
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
    var result = await resolveTestCodeWithDiagnostics(r'''
const a = 42;
List<void Function(@a int b)> f() => [];
''');

    var node = result.findNode.annotation('@a');
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: a
    element: <testLibrary>::@getter::a
    staticType: null
  element: <testLibrary>::@getter::a
''');
    _assertAnnotationValueText(node, '''
int 42
  variable: <testLibrary>::@topLevelVariable::a
''');
  }

  test_location_class_classDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 42;

@foo
class A {}
''');

    _assertAtFoo42(result);
  }

  test_location_class_constructor_formalParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 42;

class A {
  A.named(@foo int a);
}
''');

    _assertAtFoo42(result);
  }

  test_location_class_constructorDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 42;

class A {
  @foo
  A.named();
}
''');

    _assertAtFoo42(result);
  }

  test_location_class_fieldDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 42;

class A {
  @foo
  final bar = 0;
}
''');

    _assertAtFoo42(result);
  }

  test_location_enumConstant() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
enum E {
  @v
  v;
}
''');

    var node = result.findNode.annotation('@v');
    assertResolvedNodeText(node, '''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: v
    element: <testLibrary>::@enum::E::@getter::v
    staticType: null
  element: <testLibrary>::@enum::E::@getter::v
''');

    _assertAnnotationValueText(node, '''
E
  _name: String v
  index: int 0
  constructorInvocation
    constructor: <testLibrary>::@enum::E::@constructor::new
  variable: <testLibrary>::@enum::E::@field::v
''');
  }

  test_location_extensionType_representation() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 42;

extension type A(@foo int it) {}
''');

    _assertAtFoo42(result);
  }

  test_location_fieldFormal() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final Object f;
  const A(this.f);
}

class B {
  final int f;
  B({@A( A(0) ) required this.f});
}
''');
    var node = result.findNode.annotation('@A');
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
              correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
              staticType: int
          rightParenthesis: )
        correspondingParameter: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
        staticType: A
    rightParenthesis: )
  element: <testLibrary>::@class::A::@constructor::new
''');
    _assertAnnotationValueText(node, r'''
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

  test_location_forEach_declaredIdentifier() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 42;
void f(List<int> list) {
  for (@foo var x in list) {
    x;
  }
}
''');

    _assertAtFoo42(result);
  }

  test_location_forEachPartsWithDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 42;
void f() {
  for (@foo var x = 0;;) {
    x;
    break;
  }
}
''');

    _assertAtFoo42(result);
  }

  test_location_libraryDirective() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
@foo
library my;
const foo = 42;
''');

    _assertAtFoo42(result);
  }

  test_location_libraryExportDirective() async {
    newFile('$testPackageLibPath/a.dart', '');

    var result = await resolveTestCodeWithDiagnostics(r'''
@foo
export 'a.dart';
const foo = 42;
''');

    _assertAtFoo42(result);
  }

  test_location_libraryImportDirective() async {
    newFile('$testPackageLibPath/a.dart', '');

    var result = await resolveTestCodeWithDiagnostics(r'''
@foo
import 'a.dart'; // ignore:unused_import
const foo = 42;
''');

    _assertAtFoo42(result);
  }

  test_location_localVariable() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.annotation('@A');
    assertResolvedNodeText(node, '''
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
  element: <testLibrary>::@class::A::@constructor::new
''');

    var localVariable = result.findElement.localVar('x');
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
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 42;
void f() {
  @foo
  var x;
  x;
}
''');

    _assertAtFoo42(result);
  }

  test_location_methodDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 42;

class A {
  @foo
  void bar() {}
}
''');

    _assertAtFoo42(result);
  }

  test_location_partDirective() async {
    newFile('$testPackageLibPath/a.dart', r'''
part of 'test.dart';
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
@foo
part 'a.dart';
const foo = 42;
''');

    _assertAtFoo42(result);
  }

  test_location_partDirective_fileDoesNotExist() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
@foo
part 'a.dart';
//   ^^^^^^^^
// [diag.uriDoesNotExist] Target of URI doesn't exist: 'package:test/a.dart'.
const foo = 42;
''');

    _assertAtFoo42(result);
  }

  test_location_partOfDirective() async {
    var a = getFile('$testPackageLibPath/a.dart');
    var results = await resolveFilesWithDiagnostics({
      testFile: r'''
part 'a.dart';
const foo = 42;
''',
      a: r'''
@foo
part of 'test.dart';
''',
    });
    var result = results[a]!;

    _assertAtFoo42(result);
  }

  test_location_recordTypeAnnotation_named() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int f;
  const A(this.f);
}

({@A(0) int f1, String f2}) f() => throw 0;
''');
    var node = result.findNode.annotation('@A');
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
  element: <testLibrary>::@class::A::@constructor::new
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
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int f;
  const A(this.f);
}

(int, @A(0) String) f() => throw 0;
''');
    var node = result.findNode.annotation('@A');
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
  element: <testLibrary>::@class::A::@constructor::new
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
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 42;

@foo
void bar() {}
''');

    _assertAtFoo42(result);
  }

  test_location_topLevelVariableDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 42;

@foo
final bar = 0;
''');

    _assertAtFoo42(result);
  }

  test_value_class_inference_namedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int f;
  const A.named(this.f);
}

@A.named(42)
void f() {}
''');

    var node = result.findNode.annotation('@A');
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
  element: <testLibrary>::@class::A::@constructor::named
''');
    _assertAnnotationValueText(node, '''
A
  f: int 42
  constructorInvocation
    constructor: <testLibrary>::@class::A::@constructor::named
    positionalArguments
      0: int 42
''');
  }

  test_value_class_namedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
 class A {
  final int f;
  const A.named(this.f);
}

@A.named(42)
void f() {}
''');

    var node = result.findNode.singleAnnotation;
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
  element: <testLibrary>::@class::A::@constructor::named
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

  test_value_class_namedConstructor_unresolved_hasFormalParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}

void f(int named) {
  @A.named(42)
//^^^^^^^^^^^^
// [diag.invalidAnnotation] Annotation must be either a const variable reference or const constructor invocation.
  int x = 0;
//    ^
// [diag.unusedLocalVariable] The value of the local variable 'x' isn't used.
}
''');

    var node = result.findNode.singleAnnotation;
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
      element: <null>
      staticType: null
    element: <null>
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: <null>
        staticType: int
    rightParenthesis: )
  element: <null>
''');
  }

  test_value_class_staticConstField() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static const int foo = 42;
}

@A.foo
void f() {}
''');

    var node = result.findNode.annotation('@A');
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
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: null
    element: <testLibrary>::@class::A::@getter::foo
    staticType: null
  element: <testLibrary>::@class::A::@getter::foo
''');
    _assertAnnotationValueText(node, '''
int 42
  variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_value_class_unnamedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int f;
  const A(this.f);
}

@A(42)
void f() {}
''');

    var node = result.findNode.singleAnnotation;
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
  element: <testLibrary>::@class::A::@constructor::new
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
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.singleAnnotation;
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
            element: <testLibrary>::@class::C
            type: C
          element: <testLibrary>::@class::C::@constructor::new
        argumentList: ArgumentList
          leftParenthesis: (
          rightParenthesis: )
        correspondingParameter: <testLibrary>::@class::D::@constructor::new::@formalParameter::c
        staticType: C
    rightParenthesis: )
  element: <testLibrary>::@class::D::@constructor::new
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
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type const A.named(int it) {}

@A.named(42)
void f() {}
''');

    var node = result.findNode.singleAnnotation;
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
  element: <testLibrary>::@extensionType::A::@constructor::named
''');

    _assertAnnotationValueText(node, r'''
int 42
  typeNotExtensionTypeErased: A
''');
  }

  test_value_extensionType_unnamedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
extension type const A(int it) {}

@A(42)
void f() {}
''');

    var node = result.findNode.singleAnnotation;
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
  element: <testLibrary>::@extensionType::A::@constructor::new
''');

    _assertAnnotationValueText(node, r'''
int 42
  typeNotExtensionTypeErased: A
''');
  }

  test_value_genericClass_downwards_inference_namedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  final List<List<T>> f;
  const A.named(this.f);
}

@A.named([])
void f() {}
''');

    var node = result.findNode.annotation('@A');
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
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: Object?}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: Object?}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      ListLiteral
        leftBracket: [
        rightBracket: ]
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::f
          substitution: {T: Object?}
        staticType: List<List<Object?>>
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::A::@constructor::named
    substitution: {T: Object?}
''');
    _assertAnnotationValueText(node, '''
A<Object?>
  f: List<List<Object?>>
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: Object?}
    positionalArguments
      0: List<List<Object?>>
''');
  }

  test_value_genericClass_downwards_inference_unnamedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
 class A<T> {
  final List<List<T>> f;
  const A(this.f);
}

@A([])
void f() {}
''');

    var node = result.findNode.annotation('@A');
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
      ListLiteral
        leftBracket: [
        rightBracket: ]
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
          substitution: {T: Object?}
        staticType: List<List<Object?>>
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::A::@constructor::new
    substitution: {T: Object?}
''');
    _assertAnnotationValueText(node, r'''
A<Object?>
  f: List<List<Object?>>
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: Object?}
    positionalArguments
      0: List<List<Object?>>
''');
  }

  test_value_genericClass_inference_namedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  final T f;
  const A.named(this.f);
}

@A.named(42)
void f() {}
''');

    var node = result.findNode.annotation('@A');
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
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::A::@constructor::named
    substitution: {T: int}
''');
    _assertAnnotationValueText(node, '''
A<int>
  f: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericClass_inference_unnamedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

@A(42)
void f() {}
''');

    var node = result.findNode.annotation('@A');
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
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::A::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(node, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericClass_instanceGetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  T get foo {}
//      ^^^
// [diag.bodyMightCompleteNormally] The body might complete normally, causing 'null' to be returned, but the return type, 'T', is a potentially non-nullable type.
}

@A.foo
// [diag.invalidAnnotation][column 1][length 6] Annotation must be either a const variable reference or const constructor invocation.
void f() {}
''');

    var node = result.findNode.annotation('@A');
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
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: null
    element: <testLibrary>::@class::A::@getter::foo
    staticType: null
  element: <testLibrary>::@class::A::@getter::foo
''');
  }

  test_value_genericClass_namedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  final int f;
  const A.named(this.f);
}

@A.named(42)
void f() {}
''');

    var node = result.findNode.annotation('@A');
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
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: dynamic}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: dynamic}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::f
          substitution: {T: dynamic}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::A::@constructor::named
    substitution: {T: dynamic}
''');
    _assertAnnotationValueText(node, '''
A<dynamic>
  f: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: dynamic}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericClass_staticGetter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  static T get foo {}
//       ^
// [diag.typeParameterReferencedByStatic] Static members can't reference type parameters of the class.
}

@A.foo
// [diag.invalidAnnotation][column 1][length 6] Annotation must be either a const variable reference or const constructor invocation.
void f() {}
''');

    var node = result.findNode.annotation('@A');
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
      token: foo
      element: <testLibrary>::@class::A::@getter::foo
      staticType: null
    element: <testLibrary>::@class::A::@getter::foo
    staticType: null
  element: <testLibrary>::@class::A::@getter::foo
''');
    _assertAnnotationValueText(node, '''
<null>
''');
  }

  test_value_genericClass_typeArguments_namedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  final T f;
  const A.named(this.f);
}

@A<int>.named(42)
void f() {}
''');

    var node = result.findNode.annotation('@A');
    assertResolvedNodeText(node, r'''
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
        element: dart:core::@class::int
        type: int
    rightBracket: >
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::A::@constructor::named
    substitution: {T: int}
''');
    _assertAnnotationValueText(node, '''
A<int>
  f: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericClass_typeArguments_unnamedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

@A<int>(42)
void f() {}
''');

    var node = result.findNode.annotation('@A');
    assertResolvedNodeText(node, r'''
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
        element: dart:core::@class::int
        type: int
    rightBracket: >
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::A::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(node, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericClass_unnamedConstructor_noGenericMetadata() async {
    writeTestPackageConfig(PackageConfigFileBuilder(), languageVersion: '2.12');
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  final T f;
  const A(this.f);
}

@A(42)
void f() {}
''');

    var node = result.findNode.annotation('@A');
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
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
          substitution: {T: dynamic}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::A::@constructor::new
    substitution: {T: dynamic}
''');
    _assertAnnotationValueText(node, r'''
A<dynamic>
  f: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: dynamic}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericMixinApplication_inference_unnamedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

mixin M {}

class B<T> = A<T> with M;

@B(42)
void f() {}
''');

    var node = result.findNode.annotation('@B');
    assertResolvedNodeText(node, r'''
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::B::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::B::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(node, r'''
B<int>
  (super): A<int>
    f: int 42
    constructorInvocation
      constructor: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      positionalArguments
        0: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericMixinApplication_inference_unnamedConstructor_classTypeAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.annotation('@B');
    assertResolvedNodeText(node, r'''
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::B::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::B::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(node, r'''
B<int>
  (super): A<int>
    f: int 42
    constructorInvocation
      constructor: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      positionalArguments
        0: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericMixinApplication_inference_unnamedConstructor_functionTypeAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

mixin M {}

class B<T> = A<T> with M;

@B(42)
typedef T F<T>();
''');

    var node = result.findNode.annotation('@B');
    assertResolvedNodeText(node, r'''
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::B::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::B::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(node, r'''
B<int>
  (super): A<int>
    f: int 42
    constructorInvocation
      constructor: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      positionalArguments
        0: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericMixinApplication_inference_unnamedConstructor_functionTypedFormalParameter() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

mixin M {}

class B<T> = A<T> with M;

f(@B(42) g()) {}
''');

    var node = result.findNode.annotation('@B');
    assertResolvedNodeText(node, r'''
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::B::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::B::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(node, r'''
B<int>
  (super): A<int>
    f: int 42
    constructorInvocation
      constructor: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      positionalArguments
        0: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericMixinApplication_inference_unnamedConstructor_genericTypeAlias() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

mixin M {}

class B<T> = A<T> with M;

@B(42)
typedef F = void Function();
''');

    var node = result.findNode.annotation('@B');
    assertResolvedNodeText(node, r'''
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::B::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::B::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(node, r'''
B<int>
  (super): A<int>
    f: int 42
    constructorInvocation
      constructor: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      positionalArguments
        0: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericMixinApplication_inference_unnamedConstructor_methodDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
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

    var node = result.findNode.annotation('@B');
    assertResolvedNodeText(node, r'''
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
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::B::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::B::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(node, r'''
B<int>
  (super): A<int>
    f: int 42
    constructorInvocation
      constructor: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      positionalArguments
        0: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::B::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_genericMixinApplication_typeArguments_unnamedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
 class A<T> {
  final T f;
  const A(this.f);
}

mixin M {}

class B<T> = A<T> with M;

@B<int>(42)
void f() {}
''');

    var node = result.findNode.annotation('@B');
    assertResolvedNodeText(node, r'''
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
        element: dart:core::@class::int
        type: int
    rightBracket: >
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: SubstitutedFormalParameterElementImpl
          baseElement: <testLibrary>::@class::B::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::B::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(node, r'''
B<int>
  (super): A<int>
    f: int 42
    constructorInvocation
      constructor: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::new
        substitution: {T: int}
      positionalArguments
        0: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
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

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart';

void f(C c) {}
''');

    var classC = result.findNode.namedType('C c').element as ClassElement;
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

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'b.dart';

void f(B b) {}
''');

    var classB = result.findNode.namedType('B b').element! as ClassElement;
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

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'b.dart';

void f(B b) {}
''');

    var classB = result.findNode.namedType('B b').element as ClassElement;
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

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

@prefix.A.named(42)
void f() {}
''');

    var node = result.findNode.singleAnnotation;
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix::prefix
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
  element: package:test/a.dart::@class::A::@constructor::named
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

@prefix.A.foo
void f() {}
''');

    var node = result.findNode.singleAnnotation;
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix::prefix
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
  element: package:test/a.dart::@class::A::@getter::foo
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

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

@prefix.A(42)
void f() {}
''');

    var node = result.findNode.singleAnnotation;
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix::prefix
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
  element: package:test/a.dart::@class::A::@constructor::new
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

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

@prefix.foo
void f() {}
''');

    var node = result.findNode.singleAnnotation;
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix::prefix
      staticType: null
    period: .
    identifier: SimpleIdentifier
      token: foo
      element: package:test/a.dart::@getter::foo
      staticType: null
    element: package:test/a.dart::@getter::foo
    staticType: null
  element: package:test/a.dart::@getter::foo
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

@prefix.B.foo
void f() {}
''');

    var node = result.findNode.annotation('@prefix.B');
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix::prefix
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
  element: package:test/a.dart::@class::A::@getter::foo
''');
    _assertAnnotationValueText(node, '''
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

@prefix.B.named(42)
void f() {}
''');

    var node = result.findNode.annotation('@prefix.B');
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix::prefix
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
    element: SubstitutedConstructorElementImpl
      baseElement: package:test/a.dart::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: package:test/a.dart::@class::A::@constructor::named::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: package:test/a.dart::@class::A::@constructor::named
    substitution: {T: int}
''');
    _assertAnnotationValueText(node, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

@prefix.B(42)
void f() {}
''');

    var node = result.findNode.annotation('@prefix.B');
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix::prefix
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
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: package:test/a.dart::@class::A::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: package:test/a.dart::@class::A::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(node, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

@prefix.B<int>.named(42)
void f() {}
''');

    var node = result.findNode.annotation('@prefix.B');
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix::prefix
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
        element: dart:core::@class::int
        type: int
    rightBracket: >
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: SubstitutedConstructorElementImpl
      baseElement: package:test/a.dart::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: package:test/a.dart::@class::A::@constructor::named::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: package:test/a.dart::@class::A::@constructor::named
    substitution: {T: int}
''');
    _assertAnnotationValueText(node, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
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
    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' as prefix;

@prefix.B<int>(42)
void f() {}
''');

    var node = result.findNode.annotation('@prefix.B');
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: PrefixedIdentifier
    prefix: SimpleIdentifier
      token: prefix
      element: <testLibraryFragment>::@prefix::prefix
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
        element: dart:core::@class::int
        type: int
    rightBracket: >
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: package:test/a.dart::@class::A::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: package:test/a.dart::@class::A::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(node, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: package:test/a.dart::@class::A::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_topLevelVariableDeclaration() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
const foo = 42;

@foo
void f() {}
''');

    _assertAtFoo42(result);
  }

  test_value_typeAlias_class_staticConstField() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  static const int foo = 42;
}

typedef B = A;

@B.foo
void f() {}
''');

    var node = result.findNode.annotation('@B');
    assertResolvedNodeText(node, r'''
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
  element: <testLibrary>::@class::A::@getter::foo
''');
    _assertAnnotationValueText(node, '''
int 42
  variable: <testLibrary>::@class::A::@field::foo
''');
  }

  test_value_typeAlias_generic_class_generic_1of2_typeArguments_namedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T, U> {
  final T t;
  final U u;
  const A.named(this.t, this.u);
}

typedef B<T> = A<T, double>;

@B<int>.named(42, 1.2)
void f() {}
''');

    var node = result.findNode.annotation('@B');
    assertResolvedNodeText(node, r'''
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
        element: dart:core::@class::int
        type: int
    rightBracket: >
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int, U: double}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::t
          substitution: {T: int, U: double}
        staticType: int
      DoubleLiteral
        literal: 1.2
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::u
          substitution: {T: int, U: double}
        staticType: double
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::A::@constructor::named
    substitution: {T: int, U: double}
''');
    _assertAnnotationValueText(node, r'''
A<int, double>
  t: int 42
  u: double 1.2
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int, U: double}
    positionalArguments
      0: int 42
      1: double 1.2
''');
  }

  test_value_typeAlias_generic_class_generic_1of2_typeArguments_unnamedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T, U> {
  final T t;
  final U u;
  const A(this.t, this.u);
}

typedef B<T> = A<T, double>;

@B<int>(42, 1.2)
void f() {}
''');

    var node = result.findNode.annotation('@B');
    assertResolvedNodeText(node, r'''
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
        element: dart:core::@class::int
        type: int
    rightBracket: >
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::t
          substitution: {T: int, U: double}
        staticType: int
      DoubleLiteral
        literal: 1.2
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::u
          substitution: {T: int, U: double}
        staticType: double
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::A::@constructor::new
    substitution: {T: int, U: double}
''');
    _assertAnnotationValueText(node, r'''
A<int, double>
  t: int 42
  u: double 1.2
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int, U: double}
    positionalArguments
      0: int 42
      1: double 1.2
''');
  }

  test_value_typeAlias_generic_class_generic_all_inference_namedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  final T f;
  const A.named(this.f);
}

typedef B<U> = A<U>;

@B.named(42)
void f() {}
''');

    var node = result.findNode.annotation('@B');
    assertResolvedNodeText(node, r'''
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
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::A::@constructor::named
    substitution: {T: int}
''');
    _assertAnnotationValueText(node, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_typeAlias_generic_class_generic_all_inference_unnamedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  final T f;
  const A(this.f);
}

typedef B<U> = A<U>;

@B(42)
void f() {}
''');

    var node = result.findNode.annotation('@B');
    assertResolvedNodeText(node, r'''
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
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::A::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(node, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_typeAlias_generic_class_generic_all_typeArguments_namedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  final T f;
  const A.named(this.f);
}

typedef B<U> = A<U>;

@B<int>.named(42)
void f() {}
''');

    var node = result.findNode.annotation('@B');
    assertResolvedNodeText(node, r'''
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
        element: dart:core::@class::int
        type: int
    rightBracket: >
  period: .
  constructorName: SimpleIdentifier
    token: named
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::A::@constructor::named
    substitution: {T: int}
''');
    _assertAnnotationValueText(node, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_typeAlias_generic_class_generic_all_typeArguments_unnamedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  final T f;
  const A(this.f);
}

typedef B<U> = A<U>;

@B<int>(42)
void f() {}
''');

    var node = result.findNode.annotation('@B');
    assertResolvedNodeText(node, r'''
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
        element: dart:core::@class::int
        type: int
    rightBracket: >
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::A::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(node, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_typeAlias_notGeneric_class_generic_namedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  final T f;
  const A.named(this.f);
}

typedef B = A<int>;

@B.named(42)
void f() {}
''');

    var node = result.findNode.annotation('@B');
    assertResolvedNodeText(node, r'''
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
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::A::@constructor::named
        substitution: {T: int}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
    staticType: null
  arguments: ArgumentList
    leftParenthesis: (
    arguments
      IntegerLiteral
        literal: 42
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::named::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::A::@constructor::named
    substitution: {T: int}
''');
    _assertAnnotationValueText(node, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::named
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_typeAlias_notGeneric_class_generic_unnamedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A<T> {
  final T f;
  const A(this.f);
}

typedef B = A<int>;

@B(42)
void f() {}
''');

    var node = result.findNode.annotation('@B');
    assertResolvedNodeText(node, r'''
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
        correspondingParameter: SubstitutedFieldFormalParameterElementImpl
          baseElement: <testLibrary>::@class::A::@constructor::new::@formalParameter::f
          substitution: {T: int}
        staticType: int
    rightParenthesis: )
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::A::@constructor::new
    substitution: {T: int}
''');
    _assertAnnotationValueText(node, r'''
A<int>
  f: int 42
  constructorInvocation
    constructor: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::A::@constructor::new
      substitution: {T: int}
    positionalArguments
      0: int 42
''');
  }

  test_value_typeAlias_notGeneric_class_notGeneric_namedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int f;
  const A.named(this.f);
}

typedef B = A;

@B.named(42)
void f() {}
''');

    var node = result.findNode.annotation('@B');
    assertResolvedNodeText(node, r'''
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
  element: <testLibrary>::@class::A::@constructor::named
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

  test_value_typeAlias_notGeneric_class_notGeneric_unnamedConstructor() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {
  final int f;
  const A(this.f);
}

typedef B = A;

@B(42)
void f() {}
''');

    var node = result.findNode.annotation('@B');
    assertResolvedNodeText(node, r'''
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
  element: <testLibrary>::@class::A::@constructor::new
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

  void _assertAnnotationValueText(Annotation annotation, String expected) {
    var elementAnnotation = annotation.elementAnnotation!;
    _assertElementAnnotationValueText(elementAnnotation, expected);
  }

  void _assertAtFoo42(TestResolvedUnitResult result) {
    var node = result.findNode.annotation('@foo');
    assertResolvedNodeText(node, r'''
Annotation
  atSign: @
  name: SimpleIdentifier
    token: foo
    element: <testLibrary>::@getter::foo
    staticType: null
  element: <testLibrary>::@getter::foo
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
