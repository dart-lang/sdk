// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';
import 'node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassTypeAliasResolutionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class ClassTypeAliasResolutionTest extends PubPackageResolutionTest {
  //   solo_test_X() async {
  //     await resolveTestCodeWithDiagnostics(r'''
  // ''');
  //
  //     final node = result.findNode.singleListLiteral;
  //     assertResolvedNodeText(node, r'''
  // ''');
  //   }

  test_element() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
class A {}
mixin class B {}
class C {}

class X = A with B implements C;
''');

    var node = result.findNode.classTypeAlias('X =');
    assertResolvedNodeText(node, r'''
ClassTypeAlias
  typedefKeyword: class
  name: X
  equals: =
  superclass: NamedType
    name: A
    element: <testLibrary>::@class::A
    type: A
  withClause: WithClause
    withKeyword: with
    mixinTypes
      NamedType
        name: B
        element: <testLibrary>::@class::B
        type: B
  implementsClause: ImplementsClause
    implementsKeyword: implements
    interfaces
      NamedType
        name: C
        element: <testLibrary>::@class::C
        type: C
  semicolon: ;
  declaredFragment: <testLibraryFragment> X@46
''');
  }

  test_element_typeFunction_extends() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
class X = Function with A;
//        ^^^^^^^^
// [diag.finalClassExtendedOutsideOfLibrary] The class 'Function' can't be extended outside of its library because it's a final class.
''');
    var x = result.findElement.class_('X');
    assertType(x.supertype, 'Object');
  }

  test_element_typeFunction_implements() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
class B {}
class X = Object with A implements A, Function, B;
//                                    ^^^^^^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Function' can't be implemented outside of its library because it's a final class.
''');
    var x = result.findElement.class_('X');
    assertElementTypes(x.interfaces, ['A', 'B']);
  }

  test_element_typeFunction_with() async {
    var result = await resolveTestCodeWithDiagnostics(r'''
mixin class A {}
mixin class B {}
class X = Object with A, Function, B;
//                       ^^^^^^^^
// [diag.classUsedAsMixin] The class 'Function' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
    var x = result.findElement.class_('X');
    assertElementTypes(x.mixins, ['A', 'B']);
  }

  test_implicitConstructors_const() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}

mixin M {}

class C = A with M;

const x = const C();
''');
  }

  test_implicitConstructors_const_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}

mixin M {
  int i = 0;
}

class C = A with M;

const x = const C();
//        ^^^^^
// [diag.constWithNonConst] The constructor being called isn't a const constructor.
// [diag.constInitializedWithNonConstantValue] Const variables must be initialized with a constant value.
''');
  }

  test_implicitConstructors_const_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}

mixin M {
  int get i => 0;
}

class C = A with M;

const x = const C();
''');
  }

  test_implicitConstructors_const_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  const A();
}

mixin M {
  set(int i) {}
}

class C = A with M;

const x = const C();
''');
  }
}
