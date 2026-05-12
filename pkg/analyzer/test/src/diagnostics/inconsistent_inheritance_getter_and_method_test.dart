// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InconsistentInheritanceGetterAndMethodTest);
  });
}

@reflectiveTest
class InconsistentInheritanceGetterAndMethodTest
    extends PubPackageResolutionTest {
  test_class_implements_getter_implements_method_declaresField() async {
    await assertErrorsInCode(
      r'''
abstract class A {
  int get foo;
}
abstract class B {
  int foo();
}
abstract class C implements A, B {
  int foo = 0;
}
''',
      [error(diag.inconsistentInheritanceGetterAndMethod, 111, 3)],
    );
  }

  test_class_implements_getter_implements_method_declaresGetter() async {
    await assertErrorsInCode(
      r'''
abstract class A {
  int get foo;
}
abstract class B {
  int foo();
}
abstract class C implements A, B {
  int get foo => 0;
}
''',
      [error(diag.inconsistentInheritanceGetterAndMethod, 115, 3)],
    );
  }

  test_class_implements_getter_implements_method_declaresMethod() async {
    await assertErrorsInCode(
      r'''
abstract class A {
  int get foo;
}
abstract class B {
  int foo();
}
abstract class C implements A, B {
  int foo() => 0;
}
''',
      [error(diag.inconsistentInheritanceGetterAndMethod, 111, 3)],
    );
  }

  test_class_implements_getter_implements_method_declaresNoMember() async {
    await assertErrorsInCode(
      r'''
abstract class A {
  int get foo;
}
abstract class B {
  int foo();
}
abstract class C implements A, B {}
''',
      [error(diag.inconsistentInheritanceGetterAndMethod, 85, 1)],
    );
  }

  test_class_implements_method_implements_getter_declaresNoMember() async {
    await assertErrorsInCode(
      r'''
abstract class A {
  int foo();
}
abstract class B {
  int get foo;
}
abstract class C implements A, B {}
''',
      [error(diag.inconsistentInheritanceGetterAndMethod, 85, 1)],
    );
  }

  test_class_with_getter_implements_method_declaresMethod() async {
    await assertErrorsInCode(
      r'''
abstract interface class I {
  String foo();
}

mixin M {
  int get foo => 42;
}

abstract class C with M implements I {
  String foo() => 'C';
}
''',
      [error(diag.inconsistentInheritanceGetterAndMethod, 130, 3)],
    );
  }

  test_classTypeAlias_extends_getter_with_method() async {
    await assertErrorsInCode(
      '''
class S {
  int get foo => 0;
}

mixin M {
  int foo() => 0;
}

class C = S with M;
''',
      [error(diag.inconsistentInheritanceGetterAndMethod, 70, 1)],
    );
  }

  test_classTypeAlias_extends_getter_with_method_with_getter() async {
    await assertErrorsInCode(
      '''
class S {
  int get foo => 0;
}

mixin M1 {
  int foo() => 0;
}

mixin M2 {
  int get foo => 0;
}

class C = S with M1, M2;
''',
      [
        error(diag.inconsistentInheritanceGetterAndMethod, 105, 1),
        error(diag.inconsistentInheritanceGetterAndMethod, 105, 1),
      ],
    );
  }

  test_mixin_implements_getter_implements_method_declaresNoMember() async {
    await assertErrorsInCode(
      r'''
abstract class A {
  int get foo;
}
abstract class B {
  int foo();
}
mixin M implements A, B {}
''',
      [error(diag.inconsistentInheritanceGetterAndMethod, 76, 1)],
    );
  }

  test_mixin_implements_method_implements_getter_declaresNoMember() async {
    await assertErrorsInCode(
      r'''
abstract class A {
  int foo();
}
abstract class B {
  int get foo;
}
mixin M implements A, B {}
''',
      [error(diag.inconsistentInheritanceGetterAndMethod, 76, 1)],
    );
  }

  test_mixin_on_getter_implements_method_declaresField() async {
    await assertErrorsInCode(
      r'''
abstract class A {
  int get foo;
}
abstract class B {
  int foo();
}
mixin M on A implements B {
  int foo = 0;
}
''',
      [error(diag.inconsistentInheritanceGetterAndMethod, 104, 3)],
    );
  }

  test_mixin_on_getter_implements_method_declaresGetter() async {
    await assertErrorsInCode(
      r'''
abstract class A {
  int get foo;
}
abstract class B {
  int foo();
}
mixin M on A implements B {
  int get foo => 0;
}
''',
      [error(diag.inconsistentInheritanceGetterAndMethod, 108, 3)],
    );
  }

  test_mixin_on_getter_implements_method_declaresMethod() async {
    await assertErrorsInCode(
      r'''
abstract class A {
  int get foo;
}
abstract class B {
  int foo();
}
mixin M on A implements B {
  int foo() => 0;
}
''',
      [error(diag.inconsistentInheritanceGetterAndMethod, 104, 3)],
    );
  }

  test_mixin_on_getter_method_declaresNoMember() async {
    await assertErrorsInCode(
      r'''
abstract class A {
  int get foo;
}
abstract class B {
  int foo();
}
mixin M on A, B {}
''',
      [error(diag.inconsistentInheritanceGetterAndMethod, 76, 1)],
    );
  }

  test_mixin_on_method_getter_declaresNoMember() async {
    await assertErrorsInCode(
      r'''
abstract class A {
  int foo();
}
abstract class B {
  int get foo;
}
mixin M on A, B {}
''',
      [error(diag.inconsistentInheritanceGetterAndMethod, 76, 1)],
    );
  }
}
