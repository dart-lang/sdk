// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionOverrideArgumentNotAssignableTest);
  });
}

@reflectiveTest
class ExtensionOverrideArgumentNotAssignableTest
    extends PubPackageResolutionTest {
  test_override_onNonNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  void m() {}
}
f() {
  E(null).m();
//  ^^^^
// [diag.extensionOverrideArgumentNotAssignable] The type of the argument to the extension override 'Null' isn't assignable to the extended type 'String'.
}
''');
  }

  test_override_onNullable() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String? {
  void m() {}
}
f() {
  E(null).m();
}
''');
  }

  test_subtype() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {}
extension E on A {
  void m() {}
}
void f(B b) {
  E(b).m();
}
''');
  }

  test_supertype() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B extends A {}
extension E on B {
  void m() {}
}
void f(A a) {
  E(a).m();
//  ^
// [diag.extensionOverrideArgumentNotAssignable] The type of the argument to the extension override 'A' isn't assignable to the extended type 'B'.
}
''');
  }

  test_unrelated() async {
    await resolveTestCodeWithDiagnostics(r'''
class A {}
class B {}
extension E on A {
  void m() {}
}
void f(B b) {
  E(b).m();
//  ^
// [diag.extensionOverrideArgumentNotAssignable] The type of the argument to the extension override 'B' isn't assignable to the extended type 'A'.
}
''');
  }
}
