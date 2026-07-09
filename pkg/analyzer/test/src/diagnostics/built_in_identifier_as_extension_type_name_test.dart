// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuiltInIdentifierAsExtensionTypeNameTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class BuiltInIdentifierAsExtensionTypeNameTest
    extends PubPackageResolutionTest {
  test_as() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type as(int it) {}
//             ^^
// [diag.builtInIdentifierAsExtensionTypeName] The built-in identifier 'as' can't be used as an extension type name.
''');
  }

  test_Function() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type Function(int it) {}
//             ^^^^^^^^
// [diag.builtInIdentifierAsExtensionTypeName] The built-in identifier 'Function' can't be used as an extension type name.
''');
  }

  test_inout() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type inout(int it) {}
//             ^^^^^
// [diag.builtInIdentifierAsExtensionTypeName] The built-in identifier 'inout' can't be used as an extension type name.
''');
  }

  test_inout_language310() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type inout(int it) {}
''');
  }

  test_out() async {
    await resolveTestCodeWithDiagnostics(r'''
extension type out(int it) {}
//             ^^^
// [diag.builtInIdentifierAsExtensionTypeName] The built-in identifier 'out' can't be used as an extension type name.
''');
  }

  test_out_language310() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension type out(int it) {}
''');
  }
}
