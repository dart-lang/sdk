// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeWithAbstractMemberTest);
  });
}

@reflectiveTest
class ExtensionTypeWithAbstractMemberTest extends PubPackageResolutionTest {
  test_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  int get foo;
//^^^^^^^^^^^^
// [diag.extensionTypeWithAbstractMember] 'foo' must have a method body because 'A' is an extension type.
}
''');
  }

  test_getter_external() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  external int get foo;
}
''');
  }

  test_getter_static() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  static int get foo;
}
''');
  }

  test_getter_static_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type A(int it) {
  static int get foo;
//                  ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_method() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  void foo();
//^^^^^^^^^^^
// [diag.extensionTypeWithAbstractMember] 'foo' must have a method body because 'A' is an extension type.
}
''');
  }

  test_method_external() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  external void foo();
}
''');
  }

  test_method_static() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  static void foo();
}
''');
  }

  test_method_static_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type A(int it) {
  static void foo();
//                 ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }

  test_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  set foo(int _);
//^^^^^^^^^^^^^^^
// [diag.extensionTypeWithAbstractMember] 'foo' must have a method body because 'A' is an extension type.
}
''');
  }

  test_setter_external() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  external set foo(int _);
}
''');
  }

  test_setter_static() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) {
  static set foo(int _);
}
''');
  }

  test_setter_static_language305() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.5
extension type A(int it) {
  static set foo(int _);
//                     ^
// [diag.missingFunctionBody] A function body must be provided.
}
''');
  }
}
