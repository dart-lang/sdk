// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionConflictingStaticAndInstanceTest);
  });
}

@reflectiveTest
class ExtensionConflictingStaticAndInstanceTest
    extends PubPackageResolutionTest {
  test_extendedType_staticField() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int foo = 0;
  int bar = 0;
}

extension E on A {
  int get foo => 0;
  static int get bar => 0;
}
''');
  }

  test_extendedType_staticGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static int get foo => 0;
  int get bar => 0;
}

extension E on A {
  int get foo => 0;
  static int get bar => 0;
}
''');
  }

  test_extendedType_staticMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static void foo() {}
  void bar() {}
}

extension E on A {
  void foo() {}
  static void bar() {}
}
''');
  }

  test_extendedType_staticSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {
  static set foo(_) {}
  set bar(_) {}
}

extension E on A {
  set foo(_) {}
  static set bar(_) {}
}
''');
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_instanceMethod_staticMethodInAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
extension A on int {
  void foo() {}
}

augment extension A {
  static void foo() {}
}
''');
  }

  test_staticField_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  static int foo = 0;
//           ^^^
// [diag.extensionConflictingStaticAndInstance] An extension can't define static member 'foo' and an instance member with the same name.
  int get foo => 0;
}
''');
  }

  test_staticField_instanceGetter_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  static int foo = 0;
//           ^^^
// [diag.extensionConflictingStaticAndInstance] An extension can't define static member 'foo' and an instance member with the same name.
  int get foo => 0;
}
''');
  }

  test_staticField_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  static int foo = 0;
//           ^^^
// [diag.extensionConflictingStaticAndInstance] An extension can't define static member 'foo' and an instance member with the same name.
  void foo() {}
}
''');
  }

  test_staticField_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  static int foo = 0;
//           ^^^
// [diag.extensionConflictingStaticAndInstance] An extension can't define static member 'foo' and an instance member with the same name.
  set foo(_) {}
}
''');
  }

  test_staticGetter_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  static int get foo => 0;
//               ^^^
// [diag.extensionConflictingStaticAndInstance] An extension can't define static member 'foo' and an instance member with the same name.
  int get foo => 0;
}
''');
  }

  test_staticGetter_instanceGetter_unnamed() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  static int get foo => 0;
//               ^^^
// [diag.extensionConflictingStaticAndInstance] An extension can't define static member 'foo' and an instance member with the same name.
  int get foo => 0;
}
''');
  }

  test_staticGetter_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  static int get foo => 0;
//               ^^^
// [diag.extensionConflictingStaticAndInstance] An extension can't define static member 'foo' and an instance member with the same name.
  void foo() {}
}
''');
  }

  test_staticGetter_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  static int get foo => 0;
//               ^^^
// [diag.extensionConflictingStaticAndInstance] An extension can't define static member 'foo' and an instance member with the same name.
  set foo(_) {}
}
''');
  }

  test_staticMethod_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  static void foo() {}
//            ^^^
// [diag.extensionConflictingStaticAndInstance] An extension can't define static member 'foo' and an instance member with the same name.
  int get foo => 0;
}
''');
  }

  test_staticMethod_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  static void foo() {}
//            ^^^
// [diag.extensionConflictingStaticAndInstance] An extension can't define static member 'foo' and an instance member with the same name.
  void foo() {}
}
''');
  }

  @FailingTest() // TODO(scheglov): implement augmentation
  test_staticMethod_instanceMethodInAugmentation() async {
    await resolveTestCodeWithDiagnostics(r'''
extension A on int {
  static void foo() {}
}

augment extension A {
  void foo() {}
}
''');
  }

  test_staticMethod_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  static void foo() {}
//            ^^^
// [diag.extensionConflictingStaticAndInstance] An extension can't define static member 'foo' and an instance member with the same name.
  set foo(_) {}
}
''');
  }

  test_staticSetter_instanceGetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  static set foo(_) {}
//           ^^^
// [diag.extensionConflictingStaticAndInstance] An extension can't define static member 'foo' and an instance member with the same name.
  int get foo => 0;
}
''');
  }

  test_staticSetter_instanceMethod() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  static set foo(_) {}
//           ^^^
// [diag.extensionConflictingStaticAndInstance] An extension can't define static member 'foo' and an instance member with the same name.
  void foo() {}
}
''');
  }

  test_staticSetter_instanceSetter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  static set foo(_) {}
//           ^^^
// [diag.extensionConflictingStaticAndInstance] An extension can't define static member 'foo' and an instance member with the same name.
  set foo(_) {}
}
''');
  }
}
