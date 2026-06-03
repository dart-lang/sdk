// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  void hashCode() {}
//     ^^^^^^^^
// [diag.extensionDeclaresMemberOfObject] Extensions can't declare members with the same name as a member declared by 'Object'.
}
''');
  }

  test_instance_sameKind() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  bool operator==(Object _) => false;
//             ^^
// [diag.extensionDeclaresMemberOfObject] Extensions can't declare members with the same name as a member declared by 'Object'.
  int get hashCode => 0;
//        ^^^^^^^^
// [diag.extensionDeclaresMemberOfObject] Extensions can't declare members with the same name as a member declared by 'Object'.
  String toString() => '';
//       ^^^^^^^^
// [diag.extensionDeclaresMemberOfObject] Extensions can't declare members with the same name as a member declared by 'Object'.
  dynamic get runtimeType => null;
//            ^^^^^^^^^^^
// [diag.extensionDeclaresMemberOfObject] Extensions can't declare members with the same name as a member declared by 'Object'.
  dynamic noSuchMethod(_) => null;
//        ^^^^^^^^^^^^
// [diag.extensionDeclaresMemberOfObject] Extensions can't declare members with the same name as a member declared by 'Object'.
}
''');
  }

  test_static() async {
    await resolveTestCodeWithDiagnostics(r'''
extension E on String {
  static void hashCode() {}
//            ^^^^^^^^
// [diag.extensionDeclaresMemberOfObject] Extensions can't declare members with the same name as a member declared by 'Object'.
}
''');
  }
}
