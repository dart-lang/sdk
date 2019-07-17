// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NotInitializedNonNullableStaticFieldTest);
  });
}

@reflectiveTest
class NotInitializedNonNullableStaticFieldTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions =>
      AnalysisOptionsImpl()..enabledExperiments = [EnableString.non_nullable];

  test_futureOr_questionArgument_none() async {
    await assertNoErrorsInCode('''
import 'dart:async';

class A {
  static FutureOr<int?> v;
}
''');
  }

  test_hasInitializer() async {
    await assertNoErrorsInCode('''
class A {
  static int v = 0;
}
''');
  }

  test_noInitializer() async {
    await assertErrorsInCode('''
class A {
  static int x = 0, y, z = 2;
}
''', [
      error(CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_STATIC_FIELD, 30,
          1),
    ]);
  }

  test_nullable() async {
    await assertNoErrorsInCode('''
class A {
  static int? v;
}
''');
  }

  test_type_dynamic() async {
    await assertNoErrorsInCode('''
class A {
  static dynamic v;
}
''');
  }

  test_type_dynamic_implicit() async {
    await assertNoErrorsInCode('''
class A {
  static var v;
}
''');
  }

  test_type_never() async {
    await assertErrorsInCode('''
class A {
  static Never v;
}
''', [
      error(CompileTimeErrorCode.NOT_INITIALIZED_NON_NULLABLE_STATIC_FIELD, 25,
          1),
    ]);
  }

  test_type_void() async {
    await assertNoErrorsInCode('''
class A {
  static void v;
}
''');
  }
}
