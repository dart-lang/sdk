// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
class C {
  factory foo() => throw 0;
//        ^^^
// [diag.conflictingConstructorAndStaticMethod] 'foo' can't be used to name both a constructor and a static method in this class.
  static void foo() {}
}
''');
  }

  test_class_newHead_static() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  new foo();
//    ^^^
// [diag.conflictingConstructorAndStaticMethod] 'foo' can't be used to name both a constructor and a static method in this class.
  static void foo() {}
}
''');
  }

  test_class_primaryConstructor_static() async {
    await resolveTestCodeWithDiagnostics(r'''
class C.foo() {
//      ^^^
// [diag.conflictingConstructorAndStaticMethod] 'foo' can't be used to name both a constructor and a static method in this class.
  static void foo() {}
}
''');
  }

  test_class_typeName_instance() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C.foo();
  void foo() {}
}
''');
  }

  test_class_typeName_notSameClass() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo() {}
}
class B extends A {
  B.foo();
}
''');
  }

  test_class_typeName_static() async {
    await resolveTestCodeWithDiagnostics(r'''
class C {
  C.foo();
//  ^^^
// [diag.conflictingConstructorAndStaticMethod] 'foo' can't be used to name both a constructor and a static method in this class.
  static void foo() {}
}
''');
  }

  test_enum_factoryHead_static() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v;
  const E();
  factory foo() => throw 0;
//        ^^^
// [diag.conflictingConstructorAndStaticMethod] 'foo' can't be used to name both a constructor and a static method in this class.
  static void foo() {}
}
''');
  }

  test_enum_newHead_static() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v.foo();
  const new foo();
//          ^^^
// [diag.conflictingConstructorAndStaticMethod] 'foo' can't be used to name both a constructor and a static method in this class.
  static void foo() {}
}
''');
  }

  test_enum_primaryConstructor_static() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E.foo() {
//     ^^^
// [diag.conflictingConstructorAndStaticMethod] 'foo' can't be used to name both a constructor and a static method in this class.
  v.foo();
  static void foo() {}
}
''');
  }

  test_enum_typeName_instance() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v.foo();
  const E.foo();
  void foo() {}
}
''');
  }

  test_enum_typeName_static() async {
    await resolveTestCodeWithDiagnostics(r'''
enum E {
  v.foo();
  const E.foo();
//        ^^^
// [diag.conflictingConstructorAndStaticMethod] 'foo' can't be used to name both a constructor and a static method in this class.
  static void foo() {}
}
''');
  }

  test_extensionType_factoryHead_static() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A.bar(int it) {
  factory A.foo() => throw 0;
//          ^^^
// [diag.conflictingConstructorAndStaticMethod] 'foo' can't be used to name both a constructor and a static method in this class.
  static void foo() {}
}
''');
  }

  test_extensionType_newHead_static() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A.bar(int it) {
  new foo() : this.bar(0);
//    ^^^
// [diag.conflictingConstructorAndStaticMethod] 'foo' can't be used to name both a constructor and a static method in this class.
  static void foo() {}
}
''');
  }

  test_extensionType_primaryConstructor_instance() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A.foo(int it) {
  void foo() {}
}
''');
  }

  test_extensionType_primaryConstructor_static() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A.foo(int it) {
//               ^^^
// [diag.conflictingConstructorAndStaticMethod] 'foo' can't be used to name both a constructor and a static method in this class.
  static void foo() {}
}
''');
  }

  test_extensionType_typeName_static() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  A.foo(this.it);
//  ^^^
// [diag.conflictingConstructorAndStaticMethod] 'foo' can't be used to name both a constructor and a static method in this class.
  static void foo() {}
}
''');
  }
}
