// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/context_collection_resolution.dart';
import '../dart/resolution/node_text_expectations.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DeprecatedImplementsFunctionTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class DeprecatedImplementsFunctionTest extends PubPackageResolutionTest {
  test_class_core() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements Function {}
//                 ^^^^^^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Function' can't be implemented outside of its library because it's a final class.
''');
  }

  test_class_core2() async {
    await resolveTestCodeWithDiagnostics(r'''
class A implements Function, Function {}
//                 ^^^^^^^^
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Function' can't be implemented outside of its library because it's a final class.
//                           ^^^^^^^^
// [diag.implementsRepeated] 'Function' can only be implemented once.
// [diag.finalClassImplementedOutsideOfLibrary] The class 'Function' can't be implemented outside of its library because it's a final class.
''');
  }

  test_class_core2_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
class A implements Function, Function {}
//                 ^^^^^^^^
// [diag.deprecatedImplementsFunction] Implementing 'Function' has no effect.
//                           ^^^^^^^^
// [diag.implementsRepeated] 'Function' can only be implemented once.
''');
  }

  test_class_core_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
class A implements Function {}
//                 ^^^^^^^^
// [diag.deprecatedImplementsFunction] Implementing 'Function' has no effect.
''');
  }

  test_class_core_language219_viaTypedef() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
typedef F = Function;
class A implements F {}
//                 ^
// [diag.deprecatedImplementsFunction] Implementing 'Function' has no effect.
''');
  }

  test_class_local() async {
    await resolveTestCodeWithDiagnostics(r'''
class Function {}
//    ^^^^^^^^
// [diag.builtInIdentifierAsTypeName] The built-in identifier 'Function' can't be used as a type name.
class A implements Function {}
''');
  }

  test_classAlias_core_language219() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
mixin M {}
class A = Object with M implements Function;
//                                 ^^^^^^^^
// [diag.deprecatedImplementsFunction] Implementing 'Function' has no effect.
''');
  }

  test_classAlias_core_language219_viaTypedef() async {
    await resolveTestCodeWithDiagnostics(r'''
// @dart = 2.19
mixin M {}
typedef F = Function;
class A = Object with M implements F;
//                                 ^
// [diag.deprecatedImplementsFunction] Implementing 'Function' has no effect.
''');
  }
}
