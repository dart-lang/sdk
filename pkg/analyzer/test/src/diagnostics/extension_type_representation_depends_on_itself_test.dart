// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtensionTypeRepresentationDependsOnItselfTest);
  });
}

@reflectiveTest
class ExtensionTypeRepresentationDependsOnItselfTest
    extends PubPackageResolutionTest {
  test_depends_cycle2_direct() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(B it) {}
//             ^
// [diag.extensionTypeRepresentationDependsOnItself] The extension type representation can't depend on itself.

extension type B(A it) {}
//             ^
// [diag.extensionTypeRepresentationDependsOnItself] The extension type representation can't depend on itself.
''');
  }

  test_depends_cycle2_typeArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(List<B> it) {}
//             ^
// [diag.extensionTypeRepresentationDependsOnItself] The extension type representation can't depend on itself.

extension type B(List<A> it) {}
//             ^
// [diag.extensionTypeRepresentationDependsOnItself] The extension type representation can't depend on itself.
''');
  }

  test_depends_self_direct() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(A it) {}
//             ^
// [diag.extensionTypeRepresentationDependsOnItself] The extension type representation can't depend on itself.
''');
  }

  test_depends_self_typeArgument() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type A(List<A> it) {}
//             ^
// [diag.extensionTypeRepresentationDependsOnItself] The extension type representation can't depend on itself.
''');
  }
}
