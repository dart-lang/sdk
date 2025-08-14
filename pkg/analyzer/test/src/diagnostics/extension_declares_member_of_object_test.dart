// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/codes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionDeclaresMemberOfObjectTest);
  });
}

@reflectiveTest
class ExtensionDeclaresMemberOfObjectTest extends PubPackageResolutionTest {
  test_instance_differentKind() async {
    await assertErrorsInCode(
      '''
extension E on String {
  void hashCode() {}
}
''',
      [error(CompileTimeErrorCode.extensionDeclaresMemberOfObject, 31, 8)],
    );
  }

  test_instance_sameKind() async {
    await assertErrorsInCode(
      '''
extension E on String {
  bool operator==(Object _) => false;
  int get hashCode => 0;
  String toString() => '';
  dynamic get runtimeType => null;
  dynamic noSuchMethod(_) => null;
}
''',
      [
        error(CompileTimeErrorCode.extensionDeclaresMemberOfObject, 39, 2),
        error(CompileTimeErrorCode.extensionDeclaresMemberOfObject, 72, 8),
        error(CompileTimeErrorCode.extensionDeclaresMemberOfObject, 96, 8),
        error(CompileTimeErrorCode.extensionDeclaresMemberOfObject, 128, 11),
        error(CompileTimeErrorCode.extensionDeclaresMemberOfObject, 159, 12),
      ],
    );
  }

  test_static() async {
    await assertErrorsInCode(
      '''
extension E on String {
  static void hashCode() {}
}
''',
      [error(CompileTimeErrorCode.extensionDeclaresMemberOfObject, 38, 8)],
    );
  }
}
