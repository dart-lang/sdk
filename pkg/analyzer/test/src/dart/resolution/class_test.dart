// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ClassDeclarationResolutionTest);
  });
}

@reflectiveTest
class ClassDeclarationResolutionTest extends PubPackageResolutionTest {
  test_element_allSupertypes() async {
    await assertNoErrorsInCode(r'''
class A {}
mixin B {}
mixin C {}
class D {}
class E {}

class X1 extends A {}
class X2 implements B {}
class X3 extends A implements B {}
class X4 extends A with B implements C {}
class X5 extends A with B, C implements D, E {}
''');

    assertElementTypes(findElement2.class_('X1').allSupertypes, [
      'Object',
      'A',
    ]);
    assertElementTypes(findElement2.class_('X2').allSupertypes, [
      'Object',
      'B',
    ]);
    assertElementTypes(findElement2.class_('X3').allSupertypes, [
      'Object',
      'A',
      'B',
    ]);
    assertElementTypes(findElement2.class_('X4').allSupertypes, [
      'Object',
      'A',
      'B',
      'C',
    ]);
    assertElementTypes(findElement2.class_('X5').allSupertypes, [
      'Object',
      'A',
      'B',
      'C',
      'D',
      'E',
    ]);
  }

  test_element_allSupertypes_generic() async {
    await assertNoErrorsInCode(r'''
class A<T> {}
class B<T, U> {}
class C<T> extends B<int, T> {}

class X1 extends A<String> {}
class X2 extends B<String, List<int>> {}
class X3 extends C<double> {}
''');

    assertElementTypes(findElement2.class_('X1').allSupertypes, [
      'Object',
      'A<String>',
    ]);
    assertElementTypes(findElement2.class_('X2').allSupertypes, [
      'Object',
      'B<String, List<int>>',
    ]);
    assertElementTypes(findElement2.class_('X3').allSupertypes, [
      'Object',
      'B<int, double>',
      'C<double>',
    ]);
  }

  test_element_allSupertypes_recursive() async {
    await assertErrorsInCode(
      r'''
class A extends B {}
class B extends C {}
class C extends A {}

class X extends A {}
''',
      [
        error(CompileTimeErrorCode.recursiveInterfaceInheritance, 6, 1),
        error(CompileTimeErrorCode.recursiveInterfaceInheritance, 27, 1),
        error(CompileTimeErrorCode.recursiveInterfaceInheritance, 48, 1),
      ],
    );

    assertElementTypes(findElement2.class_('X').allSupertypes, ['A', 'Object']);
  }

  test_element_typeFunction_extends() async {
    await assertErrorsInCode(
      r'''
class A extends Function {}
''',
      [error(CompileTimeErrorCode.finalClassExtendedOutsideOfLibrary, 16, 8)],
    );
    var a = findElement2.class_('A');
    assertType(a.supertype, 'Object');
  }

  test_element_typeFunction_extends_language219() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.19
class A extends Function {}
''',
      [error(WarningCode.deprecatedExtendsFunction, 32, 8)],
    );
    var a = findElement2.class_('A');
    assertType(a.supertype, 'Object');
  }

  test_element_typeFunction_with() async {
    await assertErrorsInCode(
      r'''
mixin A {}
mixin B {}
class C extends Object with A, Function, B {}
''',
      [error(CompileTimeErrorCode.classUsedAsMixin, 53, 8)],
    );

    assertElementTypes(findElement2.class_('C').mixins, ['A', 'B']);
  }

  test_element_typeFunction_with_language219() async {
    await assertErrorsInCode(
      r'''
// @dart = 2.19
mixin A {}
mixin B {}
class C extends Object with A, Function, B {}
''',
      [error(WarningCode.deprecatedMixinFunction, 69, 8)],
    );

    assertElementTypes(findElement2.class_('C').mixins, ['A', 'B']);
  }

  test_issue32815() async {
    await assertErrorsInCode(
      r'''
class A<T> extends B<T> {}
class B<T> extends A<T> {}
class C<T> extends B<T> implements I<T> {}

abstract class I<T> {}

main() {
  Iterable<I<int>> x = [new C()];
}
''',
      [
        error(CompileTimeErrorCode.recursiveInterfaceInheritance, 6, 1),
        error(CompileTimeErrorCode.recursiveInterfaceInheritance, 33, 1),
        error(WarningCode.unusedLocalVariable, 150, 1),
      ],
    );
  }
}
