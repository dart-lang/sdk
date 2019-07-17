// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
//    defineReflectiveTests(FinalNotInitializedTest);
    defineReflectiveTests(FinalNotInitializedWithNnbdTest);
  });
}

@reflectiveTest
class FinalNotInitializedTest extends DriverResolutionTest {}

@reflectiveTest
class FinalNotInitializedWithNnbdTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
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
    await assertNoErrorsInCode('''
f() {
  late final x = 1;
}
''');
  }

  test_localVariable_noInitializer() async {
    await assertNoErrorsInCode('''
f() {
  late final x;
}
''');
  }
}
