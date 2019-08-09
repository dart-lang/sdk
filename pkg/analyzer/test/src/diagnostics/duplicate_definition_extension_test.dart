// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(DuplicateDefinitionExtensionTest);
  });
}

@reflectiveTest
class DuplicateDefinitionExtensionTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.extension_methods]);

  CompileTimeErrorCode get _errorCode =>
      CompileTimeErrorCode.DUPLICATE_DEFINITION;

  test_extendedType_instance() async {
    await assertNoErrorsInCode('''
class A {
  int get foo => 0;
  set foo(_) {}
  void bar() {}
}

extension E on A {
  int get foo => 0;
  set foo(_) {}
  void bar() {}
}
''');
  }

  test_extendedType_static() async {
    await assertNoErrorsInCode('''
class A {
  static int get foo => 0;
  static set foo(_) {}
  static void bar() {}
}

extension E on A {
  static int get foo => 0;
  static set foo(_) {}
  static void bar() {}
}
''');
  }

  test_instance_getter_getter() async {
    await assertErrorsInCode('''
extension E on String {
  int get foo => 0;
  int get foo => 0;
}
''', [
      error(_errorCode, 54, 3),
    ]);
  }

  test_instance_getter_setter() async {
    await assertNoErrorsInCode('''
extension E on String {
  int get foo => 0;
  set foo(_) {}
}
''');
  }

  test_instance_method_method() async {
    await assertErrorsInCode('''
extension E on String {
  void foo() {}
  void foo() {}
}
''', [
      error(_errorCode, 47, 3),
    ]);
  }

  test_instance_setter_setter() async {
    await assertErrorsInCode('''
extension E on String {
  set foo(_) {}
  set foo(_) {}
}
''', [
      error(_errorCode, 46, 3),
    ]);
  }

  test_static_getter_getter() async {
    await assertErrorsInCode('''
extension E on String {
  static int get foo => 0;
  static int get foo => 0;
}
''', [
      error(_errorCode, 68, 3),
    ]);
  }

  test_static_getter_setter() async {
    await assertNoErrorsInCode('''
extension E on String {
  static int get foo => 0;
  static set foo(_) {}
}
''');
  }

  test_static_method_method() async {
    await assertErrorsInCode('''
extension E on String {
  static void foo() {}
  static void foo() {}
}
''', [
      error(_errorCode, 61, 3),
    ]);
  }

  test_static_setter_setter() async {
    await assertErrorsInCode('''
extension E on String {
  static set foo(_) {}
  static set foo(_) {}
}
''', [
      error(_errorCode, 60, 3),
    ]);
  }
}
