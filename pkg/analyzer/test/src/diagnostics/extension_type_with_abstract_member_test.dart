// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/error/codes.dart';
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
    await assertErrorsInCode('''
extension type A(int it) {
  int get foo;
}
''', [
      error(CompileTimeErrorCode.EXTENSION_TYPE_WITH_ABSTRACT_MEMBER, 29, 12),
    ]);
  }

  test_getter_external() async {
    await assertNoErrorsInCode('''
extension type A(int it) {
  external int get foo;
}
''');
  }

  test_getter_static() async {
    await assertErrorsInCode('''
extension type A(int it) {
  static int get foo;
}
''', [
      error(ParserErrorCode.MISSING_FUNCTION_BODY, 47, 1),
    ]);
  }

  test_method() async {
    await assertErrorsInCode('''
extension type A(int it) {
  void foo();
}
''', [
      error(CompileTimeErrorCode.EXTENSION_TYPE_WITH_ABSTRACT_MEMBER, 29, 11),
    ]);
  }

  test_method_external() async {
    await assertNoErrorsInCode('''
extension type A(int it) {
  external void foo();
}
''');
  }

  test_method_static() async {
    await assertErrorsInCode('''
extension type A(int it) {
  static void foo();
}
''', [
      error(ParserErrorCode.MISSING_FUNCTION_BODY, 46, 1),
    ]);
  }

  test_setter() async {
    await assertErrorsInCode('''
extension type A(int it) {
  set foo(int _);
}
''', [
      error(CompileTimeErrorCode.EXTENSION_TYPE_WITH_ABSTRACT_MEMBER, 29, 15),
    ]);
  }

  test_setter_external() async {
    await assertNoErrorsInCode('''
extension type A(int it) {
  external set foo(int _);
}
''');
  }

  test_setter_static() async {
    await assertErrorsInCode('''
extension type A(int it) {
  static set foo(int _);
}
''', [
      error(ParserErrorCode.MISSING_FUNCTION_BODY, 50, 1),
    ]);
  }
}
