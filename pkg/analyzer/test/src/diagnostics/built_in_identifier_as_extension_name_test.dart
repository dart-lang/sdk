// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(BuiltInIdentifierAsExtensionNameTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class BuiltInIdentifierAsExtensionNameTest extends PubPackageResolutionTest {
  test_as() async {
    await resolveTestCodeWithDiagnostics(r'''
extension as on Object {}
//        ^^
// [diag.builtInIdentifierAsExtensionName] The built-in identifier 'as' can't be used as an extension name.
''');
  }

  test_Function() async {
    await resolveTestCodeWithDiagnostics(r'''
extension Function on Object {}
//        ^^^^^^^^
// [diag.builtInIdentifierAsExtensionName] The built-in identifier 'Function' can't be used as an extension name.
''');
  }

  test_inout() async {
    await resolveTestCodeWithDiagnostics(r'''
extension inout on Object {}
//        ^^^^^
// [diag.builtInIdentifierAsExtensionName] The built-in identifier 'inout' can't be used as an extension name.
''');
  }

  test_inout_language310() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension inout on Object {}
''');
  }

  test_out() async {
    await resolveTestCodeWithDiagnostics(r'''
extension out on Object {}
//        ^^^
// [diag.builtInIdentifierAsExtensionName] The built-in identifier 'out' can't be used as an extension name.
''');
  }

  test_out_language310() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 3.10
extension out on Object {}
''');
  }
}
