// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeDeclaresMemberOfObjectTest);
  });
}

@reflectiveTest
class ExtensionTypeDeclaresMemberOfObjectTest extends PubPackageResolutionTest {
  test_instance_differentKind() async {
    await assertErrorsInCode('''
extension type E(int it) {
  int get hashCode => 0;
}
''', [
      error(
          CompileTimeErrorCode.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT, 37, 8),
    ]);
  }

  test_instance_sameKind() async {
    await assertErrorsInCode('''
extension type E(int it) {
  bool operator==(Object _) => false;
  int get hashCode => 0;
  String toString() => '';
  dynamic get runtimeType => null;
  dynamic noSuchMethod(_) => null;
}
''', [
      error(
          CompileTimeErrorCode.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT, 42, 2),
      error(
          CompileTimeErrorCode.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT, 75, 8),
      error(
          CompileTimeErrorCode.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT, 99, 8),
      error(CompileTimeErrorCode.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT, 131,
          11),
      error(CompileTimeErrorCode.EXTENSION_TYPE_DECLARES_MEMBER_OF_OBJECT, 162,
          12),
    ]);
  }
}
