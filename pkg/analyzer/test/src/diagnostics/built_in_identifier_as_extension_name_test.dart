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
}
