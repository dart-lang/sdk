// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedExtendsFunctionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DeprecatedExtendsFunctionTest extends PubPackageResolutionTest {
  test_core() async {
    await resolveTestCodeWithDiagnostics(r'''
class A extends Function {}
//              ^^^^^^^^
// [diag.finalClassExtendedOutsideOfLibrary] The class 'Function' can't be extended outside of its library because it's a final class.
''');
  }

  test_core_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
class A extends Function {}
//              ^^^^^^^^
// [diag.deprecatedExtendsFunction] Extending 'Function' is deprecated.
''');
  }

  test_core_language219_viaTypedef() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
typedef F = Function;
class A extends F {}
//              ^
// [diag.deprecatedExtendsFunction] Extending 'Function' is deprecated.
''');
  }

  test_local_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
class Function {}
//    ^^^^^^^^
// [diag.builtInIdentifierAsTypeName] The built-in identifier 'Function' can't be used as a type name.
class A extends Function {}
''');
  }
}
