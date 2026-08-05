// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
class C {
  factory foo() => throw 0;
//        ^^^
// [diag.conflictingConstructorAndStaticField] 'foo' can't be used to name both a constructor and a static field in this class.
  static int foo = 0;
}
''');
  }

  test_class_newHead_static_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  new foo();
//    ^^^
// [diag.conflictingConstructorAndStaticField] 'foo' can't be used to name both a constructor and a static field in this class.
  static int foo = 0;
}
''');
  }

  test_class_primaryConstructor_static_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class C.foo() {
//      ^^^
// [diag.conflictingConstructorAndStaticField] 'foo' can't be used to name both a constructor and a static field in this class.
  static int foo = 0;
}
''');
  }

  test_class_typeName_instance_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C.foo();
  int foo = 0;
}
''');
  }

  test_class_typeName_static_field() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C.foo();
//  ^^^
// [diag.conflictingConstructorAndStaticField] 'foo' can't be used to name both a constructor and a static field in this class.
  static int foo = 0;
}
''');
  }

  test_class_typeName_static_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C.foo();
//  ^^^
// [diag.conflictingConstructorAndStaticGetter] 'foo' can't be used to name both a constructor and a static getter in this class.
  static int get foo => 0;
}
''');
  }

  test_class_typeName_static_getter_setter_pair() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C.foo();
//  ^^^
// [diag.conflictingConstructorAndStaticGetter] 'foo' can't be used to name both a constructor and a static getter in this class.
  static int get foo => 0;
  static set foo(_) {}
}
''');
  }

  test_class_typeName_static_notSameClass() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int foo = 0;
}
class B extends A {
  B.foo();
}
''');
  }

  test_class_typeName_static_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C.foo();
//  ^^^
// [diag.conflictingConstructorAndStaticSetter] 'foo' can't be used to name both a constructor and a static setter in this class.
  static void set foo(_) {}
}
''');
  }

  test_enum_factoryHead_static_field() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E();
  factory foo() => throw 0;
//        ^^^
// [diag.conflictingConstructorAndStaticField] 'foo' can't be used to name both a constructor and a static field in this class.
  static int foo = 0;
}
''');
  }

  test_enum_newHead_static_field() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v.foo();
  const new foo();
//          ^^^
// [diag.conflictingConstructorAndStaticField] 'foo' can't be used to name both a constructor and a static field in this class.
  static int foo = 0;
}
''');
  }

  test_enum_primaryConstructor_static_field() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E.foo() {
//     ^^^
// [diag.conflictingConstructorAndStaticField] 'foo' can't be used to name both a constructor and a static field in this class.
  v.foo();
  static int foo = 0;
}
''');
  }

  test_enum_typeName_constant() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  foo.foo();
  const E.foo();
//        ^^^
// [diag.conflictingConstructorAndStaticField] 'foo' can't be used to name both a constructor and a static field in this class.
}
''');
  }

  test_enum_typeName_instance_field() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v.foo();
  const E.foo();
  final int foo = 0;
}
''');
  }

  test_enum_typeName_static_field() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v.foo();
  const E.foo();
//        ^^^
// [diag.conflictingConstructorAndStaticField] 'foo' can't be used to name both a constructor and a static field in this class.
  static int foo = 0;
}
''');
  }

  test_enum_typeName_static_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v.foo();
  const E.foo();
//        ^^^
// [diag.conflictingConstructorAndStaticGetter] 'foo' can't be used to name both a constructor and a static getter in this class.
  static int get foo => 0;
}
''');
  }

  test_enum_typeName_static_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v.foo();
  const E.foo();
//        ^^^
// [diag.conflictingConstructorAndStaticSetter] 'foo' can't be used to name both a constructor and a static setter in this class.
  static void set foo(_) {}
}
''');
  }

  test_extensionType_factoryHead_static_field() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A.bar(int it) {
  factory A.foo() => throw 0;
//          ^^^
// [diag.conflictingConstructorAndStaticField] 'foo' can't be used to name both a constructor and a static field in this class.
  static int foo = 0;
}
''');
  }

  test_extensionType_newHead_static_field() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A.bar(int it) {
  new foo() : this.bar(0);
//    ^^^
// [diag.conflictingConstructorAndStaticField] 'foo' can't be used to name both a constructor and a static field in this class.
  static int foo = 0;
}
''');
  }

  test_extensionType_primaryConstructor_instance_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A.foo(int it) {
  int get foo => 0;
}
''');
  }

  test_extensionType_primaryConstructor_static_field() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A.foo(int it) {
//               ^^^
// [diag.conflictingConstructorAndStaticField] 'foo' can't be used to name both a constructor and a static field in this class.
  static int foo = 0;
}
''');
  }

  test_extensionType_primaryConstructor_static_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A.foo(int it) {
//               ^^^
// [diag.conflictingConstructorAndStaticGetter] 'foo' can't be used to name both a constructor and a static getter in this class.
  static int get foo => 0;
}
''');
  }

  test_extensionType_primaryConstructor_static_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A.foo(int it) {
//               ^^^
// [diag.conflictingConstructorAndStaticSetter] 'foo' can't be used to name both a constructor and a static setter in this class.
  static void set foo(_) {}
}
''');
  }

  test_extensionType_typeName_static_field() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  A.foo(this.it);
//  ^^^
// [diag.conflictingConstructorAndStaticField] 'foo' can't be used to name both a constructor and a static field in this class.
  static int foo = 0;
}
''');
  }
}
