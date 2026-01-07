// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConflictingConstructorAndStaticMethodTest);
  });
}

@reflectiveTest
class ConflictingConstructorAndStaticMethodTest
    extends PubPackageResolutionTest {
  test_class_factoryHead_static() async {
    await assertErrorsInCode(
      r'''
class C {
  factory foo() => throw 0;
  static void foo() {}
}
''',
      [error(diag.conflictingConstructorAndStaticMethod, 20, 3)],
    );
  }

  test_class_newHead_static() async {
    await assertErrorsInCode(
      r'''
class C {
  new foo();
  static void foo() {}
}
''',
      [error(diag.conflictingConstructorAndStaticMethod, 16, 3)],
    );
  }

  test_class_primaryConstructor_static() async {
    await assertErrorsInCode(
      r'''
class C.foo() {
  static void foo() {}
}
''',
      [error(diag.conflictingConstructorAndStaticMethod, 8, 3)],
    );
  }

  test_class_typeName_instance() async {
    await assertNoErrorsInCode(r'''
class C {
  C.foo();
  void foo() {}
}
''');
  }

  test_class_typeName_notSameClass() async {
    await assertNoErrorsInCode(r'''
class A {
  static void foo() {}
}
class B extends A {
  B.foo();
}
''');
  }

  test_class_typeName_static() async {
    await assertErrorsInCode(
      r'''
class C {
  C.foo();
  static void foo() {}
}
''',
      [error(diag.conflictingConstructorAndStaticMethod, 14, 3)],
    );
  }

  test_enum_factoryHead_static() async {
    await assertErrorsInCode(
      r'''
enum E {
  v;
  const E();
  factory foo() => throw 0;
  static void foo() {}
}
''',
      [error(diag.conflictingConstructorAndStaticMethod, 37, 3)],
    );
  }

  test_enum_newHead_static() async {
    await assertErrorsInCode(
      r'''
enum E {
  v.foo();
  const new foo();
  static void foo() {}
}
''',
      [error(diag.conflictingConstructorAndStaticMethod, 32, 3)],
    );
  }

  test_enum_primaryConstructor_static() async {
    await assertErrorsInCode(
      r'''
enum E.foo() {
  v.foo();
  static void foo() {}
}
''',
      [error(diag.conflictingConstructorAndStaticMethod, 7, 3)],
    );
  }

  test_enum_typeName_instance() async {
    await assertNoErrorsInCode(r'''
enum E {
  v.foo();
  const E.foo();
  void foo() {}
}
''');
  }

  test_enum_typeName_static() async {
    await assertErrorsInCode(
      r'''
enum E {
  v.foo();
  const E.foo();
  static void foo() {}
}
''',
      [error(diag.conflictingConstructorAndStaticMethod, 30, 3)],
    );
  }

  test_extensionType_factoryHead_static() async {
    await assertErrorsInCode(
      r'''
extension type A.bar(int it) {
  factory A.foo() => throw 0;
  static void foo() {}
}
''',
      [error(diag.conflictingConstructorAndStaticMethod, 43, 3)],
    );
  }

  test_extensionType_newHead_static() async {
    await assertErrorsInCode(
      r'''
extension type A.bar(int it) {
  new foo() : this.bar(0);
  static void foo() {}
}
''',
      [error(diag.conflictingConstructorAndStaticMethod, 37, 3)],
    );
  }

  test_extensionType_primaryConstructor_instance() async {
    await assertNoErrorsInCode(r'''
extension type A.foo(int it) {
  void foo() {}
}
''');
  }

  test_extensionType_primaryConstructor_static() async {
    await assertErrorsInCode(
      r'''
extension type A.foo(int it) {
  static void foo() {}
}
''',
      [error(diag.conflictingConstructorAndStaticMethod, 17, 3)],
    );
  }

  test_extensionType_typeName_static() async {
    await assertErrorsInCode(
      r'''
extension type A(int it) {
  A.foo(this.it);
  static void foo() {}
}
''',
      [error(diag.conflictingConstructorAndStaticMethod, 31, 3)],
    );
  }
}
