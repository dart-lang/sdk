// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedMixinFunctionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DeprecatedMixinFunctionTest extends PubPackageResolutionTest {
  test_class_core() async {
    await resolveTestCodeWithDiagnostics(r'''
class A extends Object with Function {}
//                          ^^^^^^^^
// [diag.classUsedAsMixin] The class 'Function' can't be used as a mixin because it's neither a mixin class nor a mixin.
''');
  }

  test_class_core_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
class A extends Object with Function {}
//                          ^^^^^^^^
// [diag.deprecatedMixinFunction] Mixing in 'Function' is deprecated.
''');
  }

  test_class_core_language219_viaTypedef() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
typedef F = Function;
class A extends Object with F {}
//                          ^
// [diag.deprecatedMixinFunction] Mixing in 'Function' is deprecated.
''');
  }

  test_class_local() async {
    await resolveTestCodeWithDiagnostics(r'''
mixin Function {}
//    ^^^^^^^^
// [diag.builtInIdentifierAsTypeName] The built-in identifier 'Function' can't be used as a type name.
class A extends Object with Function {}
''');
  }

  test_class_local_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
mixin Function {}
//    ^^^^^^^^
// [diag.builtInIdentifierAsTypeName] The built-in identifier 'Function' can't be used as a type name.
class A extends Object with Function {}
''');
  }

  test_classAlias_core_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
class A = Object with Function;
//                    ^^^^^^^^
// [diag.deprecatedMixinFunction] Mixing in 'Function' is deprecated.
''');
  }

  test_classAlias_core_language219_viaTypedef() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
typedef F = Function;
class A = Object with F;
//                    ^
// [diag.deprecatedMixinFunction] Mixing in 'Function' is deprecated.
''');
  }
}
