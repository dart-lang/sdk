// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeImplementsItselfTest);
  });
}

@reflectiveTest
class ExtensionTypeImplementsItselfTest extends PubPackageResolutionTest {
  test_hasCycle2() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) implements B {}
//             ^
// [diag.extensionTypeImplementsItself] The extension type can't implement itself.
extension type B(int it) implements A {}
//             ^
// [diag.extensionTypeImplementsItself] The extension type can't implement itself.
''');
  }

  test_hasCycle_self() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(int it) implements A {}
//             ^
// [diag.extensionTypeImplementsItself] The extension type can't implement itself.
''');
  }
}
