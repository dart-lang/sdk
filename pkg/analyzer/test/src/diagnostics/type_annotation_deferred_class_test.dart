// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(TypeAnnotationDeferredClassTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class TypeAnnotationDeferredClassTest extends PubPackageResolutionTest {
  test_annotation_typeArgument() async {
    newFile('$testPackageLibPath/lib1.dart', '''
class D {}
''');
    await resolveTestCodeWithDiagnostics(r'''
library root;
import 'lib1.dart' deferred as a;
class C<T> { const C(); }
@C<a.D>() main () {}
// ^^^
// [diag.typeAnnotationDeferredClass] The deferred type 'a.D' can't be used in a declaration, cast, or type test.
''');
  }

  test_asExpression() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await resolveTestCodeWithDiagnostics(r'''
library root;
import 'lib1.dart' deferred as a;
f(v) {
  v as a.A;
//     ^^^
// [diag.typeAnnotationDeferredClass] The deferred type 'a.A' can't be used in a declaration, cast, or type test.
}''');
  }

  test_catchClause() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await resolveTestCodeWithDiagnostics(r'''
library root;
import 'lib1.dart' deferred as a;
f(v) {
  try {
  } on a.A {
//     ^^^
// [diag.typeAnnotationDeferredClass] The deferred type 'a.A' can't be used in a declaration, cast, or type test.
  }
}''');
  }

  test_constructorTearOff_class_typeArgument() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' deferred as a;

class C<T> {
  C.named();
}

void f() {
  C<a.A>.named;
//  ^^^
// [diag.typeAnnotationDeferredClass] The deferred type 'a.A' can't be used in a declaration, cast, or type test.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: C
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          importPrefix: ImportPrefixReference
            name: a
            period: .
            element: <testLibraryFragment>::@prefix::a
          name: A
          element: package:test/a.dart::@class::A
          type: A
      rightBracket: >
    element: <testLibrary>::@class::C
    type: C<A>
  selector: ConstructorSelector
    period: .
    name2: named
  element: SubstitutedConstructorElementImpl
    baseElement: <testLibrary>::@class::C::@constructor::named
    substitution: {T: A}
  staticType: C<A> Function()
V1: ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: C
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            importPrefix: ImportPrefixReference
              name: a
              period: .
              element: <testLibraryFragment>::@prefix::a
            name: A
            element: package:test/a.dart::@class::A
            type: A
        rightBracket: >
      element: <testLibrary>::@class::C
      type: null
    period: .
    name: SimpleIdentifier
      token: named
      element: SubstitutedConstructorElementImpl
        baseElement: <testLibrary>::@class::C::@constructor::named
        substitution: {T: A}
      staticType: null
    element: SubstitutedConstructorElementImpl
      baseElement: <testLibrary>::@class::C::@constructor::named
      substitution: {T: A}
  staticType: C<A> Function()
''');
  }

  test_constructorTearOff_recordTypeAlias_typeArgument() async {
    newFile('$testPackageLibPath/a.dart', r'''
class A {}
''');

    var result = await resolveTestCodeWithDiagnostics(r'''
import 'a.dart' deferred as a;

typedef R<T> = (T,);

void f() {
  R<a.A>.foo;
//  ^^^
// [diag.typeAnnotationDeferredClass] The deferred type 'a.A' can't be used in a declaration, cast, or type test.
//       ^^^
// [diag.classInstantiationAccessToMemberNoConstructors] The type alias 'R' doesn't have a constructor named 'foo'.
}
''');

    var node = result.findNode.singleExpressionStatement.expression2;
    assertResolvedNodeText(node, r'''
ConstructorTearOff
  typeReference: ConstructorTypeReference
    name: R
    typeArguments: TypeArgumentList
      leftBracket: <
      arguments
        NamedType
          importPrefix: ImportPrefixReference
            name: a
            period: .
            element: <testLibraryFragment>::@prefix::a
          name: A
          element: package:test/a.dart::@class::A
          type: A
      rightBracket: >
    element: <testLibrary>::@typeAlias::R
    type: (A,)
      alias: <testLibrary>::@typeAlias::R
        typeArguments
          A
  selector: ConstructorSelector
    period: .
    name2: foo
  element: <null>
  staticType: InvalidType
V1: ConstructorReference
  constructorName: ConstructorName
    type: NamedType
      name: R
      typeArguments: TypeArgumentList
        leftBracket: <
        arguments
          NamedType
            importPrefix: ImportPrefixReference
              name: a
              period: .
              element: <testLibraryFragment>::@prefix::a
            name: A
            element: package:test/a.dart::@class::A
            type: A
        rightBracket: >
      element: <testLibrary>::@typeAlias::R
      type: null
    period: .
    name: SimpleIdentifier
      token: foo
      element: <null>
      staticType: null
    element: <null>
  staticType: InvalidType
''');
  }

  test_fieldFormalParameter() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await resolveTestCodeWithDiagnostics(r'''
library root;
import 'lib1.dart' deferred as a;
class C {
  var v;
  C(a.A this.v);
//  ^^^
// [diag.typeAnnotationDeferredClass] The deferred type 'a.A' can't be used in a declaration, cast, or type test.
}''');
  }

  test_functionDeclaration_returnType() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await resolveTestCodeWithDiagnostics(r'''
library root;
import 'lib1.dart' deferred as a;
a.A? f() { return null; }
// [diag.typeAnnotationDeferredClass][column 1][length 4] The deferred type 'a.A' can't be used in a declaration, cast, or type test.
''');
  }

  test_functionTypedFormalParameter_returnType() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await resolveTestCodeWithDiagnostics(
      r'''
library root;
import 'lib1.dart' deferred as a;
f(a.A g()) {}
//^^^
// [diag.typeAnnotationDeferredClass] The deferred type 'a.A' can't be used in a declaration, cast, or type test.''',
    );
  }

  test_isExpression() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await resolveTestCodeWithDiagnostics(r'''
library root;
import 'lib1.dart' deferred as a;
f(v) {
  bool b = v is a.A;
//     ^
// [diag.unusedLocalVariable] The value of the local variable 'b' isn't used.
//              ^^^
// [diag.typeAnnotationDeferredClass] The deferred type 'a.A' can't be used in a declaration, cast, or type test.
}''');
  }

  test_methodDeclaration_returnType() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await resolveTestCodeWithDiagnostics(r'''
library root;
import 'lib1.dart' deferred as a;
class C {
  a.A? m() { return null; }
//^^^^
// [diag.typeAnnotationDeferredClass] The deferred type 'a.A' can't be used in a declaration, cast, or type test.
}''');
  }

  test_simpleFormalParameter() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await resolveTestCodeWithDiagnostics(
      r'''
library root;
import 'lib1.dart' deferred as a;
f(a.A v) {}
//^^^
// [diag.typeAnnotationDeferredClass] The deferred type 'a.A' can't be used in a declaration, cast, or type test.''',
    );
  }

  test_typeArgumentList() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await resolveTestCodeWithDiagnostics(r'''
library root;
import 'lib1.dart' deferred as a;
class C<E> {}
C<a.A> c = C();
//^^^
// [diag.typeAnnotationDeferredClass] The deferred type 'a.A' can't be used in a declaration, cast, or type test.
''');
  }

  test_typeArgumentList2() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await resolveTestCodeWithDiagnostics(r'''
library root;
import 'lib1.dart' deferred as a;
class C<E, F> {}
C<a.A, a.A> c = C();
//^^^
// [diag.typeAnnotationDeferredClass] The deferred type 'a.A' can't be used in a declaration, cast, or type test.
//     ^^^
// [diag.typeAnnotationDeferredClass] The deferred type 'a.A' can't be used in a declaration, cast, or type test.
''');
  }

  test_typeParameter_bound() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await resolveTestCodeWithDiagnostics(
      r'''
library root;
import 'lib1.dart' deferred as a;
class C<E extends a.A> {}
//                ^^^
// [diag.typeAnnotationDeferredClass] The deferred type 'a.A' can't be used in a declaration, cast, or type test.''',
    );
  }

  test_variableDeclarationList() async {
    newFile('$testPackageLibPath/lib1.dart', '''
library lib1;
class A {}''');
    await resolveTestCodeWithDiagnostics(r'''
library root;
import 'lib1.dart' deferred as a;
a.A v = a.A();
// [diag.typeAnnotationDeferredClass][column 1][length 3] The deferred type 'a.A' can't be used in a declaration, cast, or type test.
''');
  }
}
