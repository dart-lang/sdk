// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingConstructorAndStaticFieldTest);
  });
}

@reflectiveTest
class ConflictingConstructorAndStaticFieldTest
    extends PubPackageResolutionTest {
  test_class_factoryHead_static_field() async {
    await assertErrorsInCode(
      r'''
class C {
  factory foo() => throw 0;
  static int foo = 0;
}
''',
      [error(diag.conflictingConstructorAndStaticField, 20, 3)],
    );
  }

  test_class_newHead_static_field() async {
    await assertErrorsInCode(
      r'''
class C {
  new foo();
  static int foo = 0;
}
''',
      [error(diag.conflictingConstructorAndStaticField, 16, 3)],
    );
  }

  test_class_primaryConstructor_static_field() async {
    await assertErrorsInCode(
      r'''
class C.foo() {
  static int foo = 0;
}
''',
      [error(diag.conflictingConstructorAndStaticField, 8, 3)],
    );
  }

  test_class_typeName_instance_field() async {
    await assertNoErrorsInCode(r'''
class C {
  C.foo();
  int foo = 0;
}
''');
  }

  test_class_typeName_static_field() async {
    await assertErrorsInCode(
      r'''
class C {
  C.foo();
  static int foo = 0;
}
''',
      [error(diag.conflictingConstructorAndStaticField, 14, 3)],
    );
  }

  test_class_typeName_static_getter() async {
    await assertErrorsInCode(
      r'''
class C {
  C.foo();
  static int get foo => 0;
}
''',
      [error(diag.conflictingConstructorAndStaticGetter, 14, 3)],
    );
  }

  test_class_typeName_static_getter_setter_pair() async {
    await assertErrorsInCode(
      r'''
class C {
  C.foo();
  static int get foo => 0;
  static set foo(_) {}
}
''',
      [error(diag.conflictingConstructorAndStaticGetter, 14, 3)],
    );
  }

  test_class_typeName_static_notSameClass() async {
    await assertNoErrorsInCode(r'''
class A {
  static int foo = 0;
}
class B extends A {
  B.foo();
}
''');
  }

  test_class_typeName_static_setter() async {
    await assertErrorsInCode(
      r'''
class C {
  C.foo();
  static void set foo(_) {}
}
''',
      [error(diag.conflictingConstructorAndStaticSetter, 14, 3)],
    );
  }

  test_enum_factoryHead_static_field() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  const E();
  factory foo() => throw 0;
  static int foo = 0;
}
''',
      [error(diag.conflictingConstructorAndStaticField, 37, 3)],
    );
  }

  test_enum_newHead_static_field() async {
    await assertErrorsInCode(
      r'''
enum E {
  v.foo();
  const new foo();
  static int foo = 0;
}
''',
      [error(diag.conflictingConstructorAndStaticField, 32, 3)],
    );
  }

  test_enum_primaryConstructor_static_field() async {
    await assertErrorsInCode(
      r'''
enum E.foo() {
  v.foo();
  static int foo = 0;
}
''',
      [error(diag.conflictingConstructorAndStaticField, 7, 3)],
    );
  }

  test_enum_typeName_constant() async {
    await assertErrorsInCode(
      r'''
enum E {
  foo.foo();
  const E.foo();
}
''',
      [error(diag.conflictingConstructorAndStaticField, 32, 3)],
    );
  }

  test_enum_typeName_instance_field() async {
    await assertNoErrorsInCode(r'''
enum E {
  v.foo();
  const E.foo();
  final int foo = 0;
}
''');
  }

  test_enum_typeName_static_field() async {
    await assertErrorsInCode(
      r'''
enum E {
  v.foo();
  const E.foo();
  static int foo = 0;
}
''',
      [error(diag.conflictingConstructorAndStaticField, 30, 3)],
    );
  }

  test_enum_typeName_static_getter() async {
    await assertErrorsInCode(
      r'''
enum E {
  v.foo();
  const E.foo();
  static int get foo => 0;
}
''',
      [error(diag.conflictingConstructorAndStaticGetter, 30, 3)],
    );
  }

  test_enum_typeName_static_setter() async {
    await assertErrorsInCode(
      r'''
enum E {
  v.foo();
  const E.foo();
  static void set foo(_) {}
}
''',
      [error(diag.conflictingConstructorAndStaticSetter, 30, 3)],
    );
  }

  test_extensionType_factoryHead_static_field() async {
    await assertErrorsInCode(
      r'''
extension type A.bar(int it) {
  factory A.foo() => throw 0;
  static int foo = 0;
}
''',
      [error(diag.conflictingConstructorAndStaticField, 43, 3)],
    );
  }

  test_extensionType_newHead_static_field() async {
    await assertErrorsInCode(
      r'''
extension type A.bar(int it) {
  new foo() : this.bar(0);
  static int foo = 0;
}
''',
      [error(diag.conflictingConstructorAndStaticField, 37, 3)],
    );
  }

  test_extensionType_primaryConstructor_instance_getter() async {
    await assertNoErrorsInCode(r'''
extension type A.foo(int it) {
  int get foo => 0;
}
''');
  }

  test_extensionType_primaryConstructor_static_field() async {
    await assertErrorsInCode(
      r'''
extension type A.foo(int it) {
  static int foo = 0;
}
''',
      [error(diag.conflictingConstructorAndStaticField, 17, 3)],
    );
  }

  test_extensionType_primaryConstructor_static_getter() async {
    await assertErrorsInCode(
      r'''
extension type A.foo(int it) {
  static int get foo => 0;
}
''',
      [error(diag.conflictingConstructorAndStaticGetter, 17, 3)],
    );
  }

  test_extensionType_primaryConstructor_static_setter() async {
    await assertErrorsInCode(
      r'''
extension type A.foo(int it) {
  static void set foo(_) {}
}
''',
      [error(diag.conflictingConstructorAndStaticSetter, 17, 3)],
    );
  }

  test_extensionType_typeName_static_field() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  A.foo(this.it);
  static int foo = 0;
}
''',
      [error(diag.conflictingConstructorAndStaticField, 31, 3)],
    );
  }
}
