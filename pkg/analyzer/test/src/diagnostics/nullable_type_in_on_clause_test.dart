// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NullableTypeInOnClauseTest);
  });
}

@reflectiveTest
class NullableTypeInOnClauseTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.non_nullable],
    );

  test_nonNullable() async {
    await assertNoErrorsInCode('''
class A {}
mixin B on A {}
''');
  }

  test_nullable() async {
    await assertErrorsInCode('''
class A {}
mixin B on A? {}
''', [
      error(CompileTimeErrorCode.NULLABLE_TYPE_IN_ON_CLAUSE, 22, 2),
    ]);
  }
}
