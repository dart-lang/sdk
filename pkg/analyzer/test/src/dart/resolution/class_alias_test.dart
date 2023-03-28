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
  test_defaultConstructor() async {
    await assertNoErrorsInCode(r'''
class A {}
mixin class M {}
class X = A with M;
''');
    assertConstructors(findElement.class_('X'), ['X X()']);
  }

  test_element() async {
    await assertNoErrorsInCode(r'''
class A {}
mixin class B {}
class C {}

class X = A with B implements C;
''');

    var x = findElement.class_('X');

    assertNamedType(findNode.namedType('A with'), findElement.class_('A'), 'A');
    assertNamedType(findNode.namedType('B impl'), findElement.class_('B'), 'B');
    assertNamedType(findNode.namedType('C;'), findElement.class_('C'), 'C');

    assertType(x.supertype, 'A');
    assertElementTypes(x.mixins, ['B']);
    assertElementTypes(x.interfaces, ['C']);
  }

  test_element_typeFunction_extends() async {
    await assertErrorsInCode(r'''
mixin class A {}
class X = Function with A;
''', [
      error(
          CompileTimeErrorCode.FINAL_CLASS_EXTENDED_OUTSIDE_OF_LIBRARY, 27, 8),
    ]);
    var x = findElement.class_('X');
    assertType(x.supertype, 'Object');
  }

  test_element_typeFunction_implements() async {
    await assertErrorsInCode(r'''
mixin class A {}
class B {}
class X = Object with A implements A, Function, B;
''', [
      error(CompileTimeErrorCode.FINAL_CLASS_IMPLEMENTED_OUTSIDE_OF_LIBRARY, 66,
          8),
    ]);
    var x = findElement.class_('X');
    assertElementTypes(x.interfaces, ['A', 'B']);
  }

  test_element_typeFunction_with() async {
    await assertErrorsInCode(r'''
mixin class A {}
mixin class B {}
class X = Object with A, Function, B;
''', [
      error(CompileTimeErrorCode.CLASS_USED_AS_MIXIN, 59, 8),
    ]);
    var x = findElement.class_('X');
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
    await assertErrorsInCode(r'''
class A {
  const A();
}

mixin M {
  int i = 0;
}

class C = A with M;

const x = const C();
''', [
      error(CompileTimeErrorCode.CONST_WITH_NON_CONST, 83, 5),
      error(CompileTimeErrorCode.CONST_INITIALIZED_WITH_NON_CONSTANT_VALUE, 83,
          5),
    ]);
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

  test_implicitConstructors_dependencies() async {
    await assertNoErrorsInCode(r'''
class A {
  A(int i);
}
mixin class M1 {}
mixin class M2 {}

class C2 = C1 with M2;
class C1 = A with M1;
''');

    assertConstructors(findElement.class_('C1'), ['C1 C1(int i)']);
    assertConstructors(findElement.class_('C2'), ['C2 C2(int i)']);
  }

  test_implicitConstructors_optionalParameters() async {
    await assertNoErrorsInCode(r'''
class A {
  A.c1(int a);
  A.c2(int a, [int? b, int c = 0]);
  A.c3(int a, {int? b, int c = 0});
}

mixin M {}

class C = A with M;
''');

    assertConstructors(
      findElement.class_('C'),
      [
        'C C.c1(int a)',
        'C C.c2(int a, [int b, int c = 0])',
        'C C.c3(int a, {int b, int c = 0})'
      ],
    );
  }

  test_implicitConstructors_requiredParameters() async {
    await assertNoErrorsInCode(r'''
class A<T extends num> {
  A(T x, T y);
}

mixin M {}

class B<E extends num> = A<E> with M;
''');

    assertConstructors(findElement.class_('B'), ['B<E> B(E x, E y)']);
  }
}
