// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/error/syntactic_errors.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../dart/resolution/driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(NonNullOptOutTest);
  });
}

@reflectiveTest
class NonNullOptOutTest extends DriverResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  test_nnbd_optOut_invalidSyntax() async {
    await assertErrorsInCode('''
// @dart = 2.2
// NNBD syntax is not allowed
f(x, z) { (x is String?) ? x : z; }
''', [error(ParserErrorCode.EXPERIMENT_NOT_ENABLED, 67, 1)]);
  }

  test_nnbd_optOut_late() async {
    await assertNoErrorsInCode('''
// @dart = 2.2
class C {
  // "late" is allowed as an identifier
  int late;
}
''');
  }

  @failingTest
  test_nnbd_optOut_transformsOptedInSignatures() async {
    // Failing because we don't transform opted out signatures.
    await assertNoErrorsInCode('''
// @dart = 2.2
f(String x) {
  x + null; // OK because we're in a nullable library.
}
''');
  }
}
