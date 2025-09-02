// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassTypeAliasResolutionTest);
  });
}

@reflectiveTest
class ClassTypeAliasResolutionTest extends PubPackageResolutionTest {
  //   solo_test_X() async {
  //     await assertNoErrorsInCode(r'''
  // ''');
  //
  //     final node = findNode.singleListLiteral;
  //     assertResolvedNodeText(node, r'''
  // ''');
  //   }

  test_element() async {
    await assertNoErrorsInCode(r'''
class A {}
mixin class B {}
class C {}

class X = A with B implements C;
''');

    var node = findNode.classTypeAlias('X =');
    assertResolvedNodeText(node, r'''
ClassTypeAlias
  typedefKeyword: class
  name: X
  equals: =
  superclass: NamedType
    name: A
    element2: <testLibrary>::@class::A
    type: A
  withClause: WithClause
    withKeyword: with
    mixinTypes
      NamedType
        name: B
        element2: <testLibrary>::@class::B
        type: B
  implementsClause: ImplementsClause
    implementsKeyword: implements
    interfaces
      NamedType
        name: C
        element2: <testLibrary>::@class::C
        type: C
  semicolon: ;
  declaredElement: <testLibraryFragment> X@46
''');
  }

  test_element_typeFunction_extends() async {
    await assertErrorsInCode(
      r'''
mixin class A {}
class X = Function with A;
''',
      [error(CompileTimeErrorCode.finalClassExtendedOutsideOfLibrary, 27, 8)],
    );
    var x = findElement2.class_('X');
    assertType(x.supertype, 'Object');
  }

  test_element_typeFunction_implements() async {
    await assertErrorsInCode(
      r'''
mixin class A {}
class B {}
class X = Object with A implements A, Function, B;
''',
      [
        error(
          CompileTimeErrorCode.finalClassImplementedOutsideOfLibrary,
          66,
          8,
        ),
      ],
    );
    var x = findElement2.class_('X');
    assertElementTypes(x.interfaces, ['A', 'B']);
  }

  test_element_typeFunction_with() async {
    await assertErrorsInCode(
      r'''
mixin class A {}
mixin class B {}
class X = Object with A, Function, B;
''',
      [error(CompileTimeErrorCode.classUsedAsMixin, 59, 8)],
    );
    var x = findElement2.class_('X');
    assertElementTypes(x.mixins, ['A', 'B']);
  }

  test_implicitConstructors_const() async {
    await assertNoErrorsInCode(r'''
class A {
  const A();
}

mixin M {}

class C = A with M;

const x = const C();
''');
  }

  test_implicitConstructors_const_field() async {
    await assertErrorsInCode(
      r'''
class A {
  const A();
}

mixin M {
  int i = 0;
}

class C = A with M;

const x = const C();
''',
      [
        error(CompileTimeErrorCode.constWithNonConst, 83, 5),
        error(CompileTimeErrorCode.constInitializedWithNonConstantValue, 83, 5),
      ],
    );
  }

  test_implicitConstructors_const_getter() async {
    await assertNoErrorsInCode(r'''
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
    await assertNoErrorsInCode(r'''
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
