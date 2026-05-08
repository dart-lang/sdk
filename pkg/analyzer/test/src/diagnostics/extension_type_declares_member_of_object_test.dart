// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
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
    await assertErrorsInCode(
      '''
extension type E(int it) {
  int get hashCode => 0;
}
''',
      [error(diag.extensionTypeDeclaresMemberOfObject, 37, 8)],
    );
  }

  test_instance_sameKind() async {
    await assertErrorsInCode(
      '''
extension type E(int it) {
  bool operator==(Object _) => false;
  int get hashCode => 0;
  String toString() => '';
  dynamic get runtimeType => null;
  dynamic noSuchMethod(_) => null;
}
''',
      [
        error(diag.extensionTypeDeclaresMemberOfObject, 42, 2),
        error(diag.extensionTypeDeclaresMemberOfObject, 75, 8),
        error(diag.extensionTypeDeclaresMemberOfObject, 99, 8),
        error(diag.extensionTypeDeclaresMemberOfObject, 131, 11),
        error(diag.extensionTypeDeclaresMemberOfObject, 162, 12),
      ],
    );
  }

  test_representation() async {
    await assertErrorsInCode(
      '''
extension type E0(Object? hashCode) {}
extension type E1(Object? noSuchMethod) {}
extension type E2(Object? runtimeType) {}
extension type E3(Object? toString) {}
''',
      [
        error(diag.extensionTypeDeclaresMemberOfObject, 26, 8),
        error(diag.extensionTypeDeclaresMemberOfObject, 65, 12),
        error(diag.extensionTypeDeclaresMemberOfObject, 108, 11),
        error(diag.extensionTypeDeclaresMemberOfObject, 150, 8),
      ],
    );
  }

  test_static_getter() async {
    await assertErrorsInCode(
      '''
extension type E(int it) {
  static int get hashCode => 0;
  static int get noSuchMethod => 0;
  static int get runtimeType => 0;
  static int get toString => 0;
}
''',
      [
        error(diag.extensionTypeDeclaresMemberOfObject, 44, 8),
        error(diag.extensionTypeDeclaresMemberOfObject, 76, 12),
        error(diag.extensionTypeDeclaresMemberOfObject, 112, 11),
        error(diag.extensionTypeDeclaresMemberOfObject, 147, 8),
      ],
    );
  }

  test_static_method() async {
    await assertErrorsInCode(
      '''
extension type E(int it) {
  static int hashCode() => 0;
  static dynamic noSuchMethod(Invocation i) => null;
  static Type runtimeType() => int;
  static String toString() => '';
}
''',
      [
        error(diag.extensionTypeDeclaresMemberOfObject, 40, 8),
        error(diag.extensionTypeDeclaresMemberOfObject, 74, 12),
        error(diag.extensionTypeDeclaresMemberOfObject, 124, 11),
        error(diag.extensionTypeDeclaresMemberOfObject, 162, 8),
      ],
    );
  }

  test_static_setter() async {
    await assertErrorsInCode(
      '''
extension type E(int it) {
  static set hashCode(int _) {}
  static set noSuchMethod(int _) {}
  static set runtimeType(int _) {}
  static set toString(int _) {}
}
''',
      [
        error(diag.extensionTypeDeclaresMemberOfObject, 40, 8),
        error(diag.extensionTypeDeclaresMemberOfObject, 72, 12),
        error(diag.extensionTypeDeclaresMemberOfObject, 108, 11),
        error(diag.extensionTypeDeclaresMemberOfObject, 143, 8),
      ],
    );
  }
}
