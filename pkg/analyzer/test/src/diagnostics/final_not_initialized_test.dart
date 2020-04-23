// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FinalNotInitializedTest);
    defineReflectiveTests(FinalNotInitializedWithNnbdTest);
  });
}

@reflectiveTest
class FinalNotInitializedTest extends DriverResolutionTest {
  test_class_instanceField_final_factoryConstructor_only() async {
    await assertNoErrorsInCode('''
class A {
  final int x;

  factory A() => throw 0;
}''');
  }

  test_extension_static() async {
    await assertErrorsInCode('''
extension E on String {
  static final F;
}''', [
      error(StaticWarningCode.FINAL_NOT_INITIALIZED, 39, 1),
    ]);
  }

  test_instanceField_final() async {
    await assertErrorsInCode('''
class A {
  final F;
}''', [
      error(StaticWarningCode.FINAL_NOT_INITIALIZED, 18, 1),
    ]);
  }

  test_instanceField_final_static() async {
    await assertErrorsInCode('''
class A {
  static final F;
}''', [
      error(StaticWarningCode.FINAL_NOT_INITIALIZED, 25, 1),
    ]);
  }

  test_library_final() async {
    await assertErrorsInCode('''
final F;
''', [
      error(StaticWarningCode.FINAL_NOT_INITIALIZED, 6, 1),
    ]);
  }

  test_local_final() async {
    await assertErrorsInCode('''
f() {
  final int x;
}''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 18, 1),
      error(StaticWarningCode.FINAL_NOT_INITIALIZED, 18, 1),
    ]);
  }

  test_mixin() async {
    await assertErrorsInCode('''
mixin M {
  final int x;
}
''', [
      error(StaticWarningCode.FINAL_NOT_INITIALIZED, 22, 1),
    ]);
  }
}

@reflectiveTest
class FinalNotInitializedWithNnbdTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  test_field_noConstructor_initializer() async {
    await assertNoErrorsInCode('''
class C {
  late final f = 1;
}
''');
  }

  test_field_noConstructor_noInitializer() async {
    await assertNoErrorsInCode('''
class C {
  late final f;
}
''');
  }

  test_field_unnamedConstructor_constructorInitializer() async {
    await assertNoErrorsInCode('''
class C {
  late final f;
  C() : f = 2;
}
''');
  }

  test_field_unnamedConstructor_fieldFormalParameter() async {
    await assertNoErrorsInCode('''
class C {
  late final f;
  C(this.f);
}
''');
  }

  test_field_unnamedConstructor_initializer() async {
    await assertNoErrorsInCode('''
class C {
  late final f = 1;
  C();
}
''');
  }

  test_field_unnamedConstructor_noInitializer() async {
    await assertNoErrorsInCode('''
class C {
  late final f;
  C();
}
''');
  }

  test_localVariable_initializer() async {
    await assertErrorsInCode('''
f() {
  late final x = 1;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 19, 1),
    ]);
  }

  test_localVariable_noInitializer() async {
    await assertErrorsInCode('''
f() {
  late final x;
}
''', [
      error(HintCode.UNUSED_LOCAL_VARIABLE, 19, 1),
    ]);
  }
}
