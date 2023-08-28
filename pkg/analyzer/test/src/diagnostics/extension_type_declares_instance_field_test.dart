// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeDeclaresInstanceFieldTest);
  });
}

@reflectiveTest
class ExtensionTypeDeclaresInstanceFieldTest extends PubPackageResolutionTest {
  test_instance_field() async {
    await assertErrorsInCode('''
extension type E(int it) {
  final int foo = 0;
}
''', [
      error(CompileTimeErrorCode.EXTENSION_TYPE_DECLARES_INSTANCE_FIELD, 39, 3),
    ]);
  }

  test_instance_field_external() async {
    await assertNoErrorsInCode('''
extension type E(int it) {
  external int foo;
}
''');
  }

  test_instance_getter() async {
    await assertNoErrorsInCode('''
extension type E(int it) {
  int get foo => 0;
}
''');
  }

  test_instance_setter() async {
    await assertNoErrorsInCode('''
extension type E(int it) {
  set foo(int _) {}
}
''');
  }

  test_static_field() async {
    await assertNoErrorsInCode('''
extension type E(int it) {
  static final int foo = 0;
}
''');
  }
}
