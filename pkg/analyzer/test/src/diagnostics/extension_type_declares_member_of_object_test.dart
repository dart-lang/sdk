// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  int get hashCode => 0;
//        ^^^^^^^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
}
''');
  }

  test_instance_sameKind() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  bool operator==(Object _) => false;
//             ^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
  int get hashCode => 0;
//        ^^^^^^^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
  String toString() => '';
//       ^^^^^^^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
  dynamic get runtimeType => null;
//            ^^^^^^^^^^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
  dynamic noSuchMethod(_) => null;
//        ^^^^^^^^^^^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
}
''');
  }

  test_representation() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E0(Object? hashCode) {}
//                        ^^^^^^^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
extension type E1(Object? noSuchMethod) {}
//                        ^^^^^^^^^^^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
extension type E2(Object? runtimeType) {}
//                        ^^^^^^^^^^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
extension type E3(Object? toString) {}
//                        ^^^^^^^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
''');
  }

  test_static_getter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static int get hashCode => 0;
//               ^^^^^^^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
  static int get noSuchMethod => 0;
//               ^^^^^^^^^^^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
  static int get runtimeType => 0;
//               ^^^^^^^^^^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
  static int get toString => 0;
//               ^^^^^^^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
}
''');
  }

  test_static_method() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static int hashCode() => 0;
//           ^^^^^^^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
  static dynamic noSuchMethod(Invocation i) => null;
//               ^^^^^^^^^^^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
  static Type runtimeType() => int;
//            ^^^^^^^^^^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
  static String toString() => '';
//              ^^^^^^^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
}
''');
  }

  test_static_setter() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type E(int it) {
  static set hashCode(int _) {}
//           ^^^^^^^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
  static set noSuchMethod(int _) {}
//           ^^^^^^^^^^^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
  static set runtimeType(int _) {}
//           ^^^^^^^^^^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
  static set toString(int _) {}
//           ^^^^^^^^
// [diag.extensionTypeDeclaresMemberOfObject] Extension types can't declare members with the same name as a member declared by 'Object'.
}
''');
  }
}
