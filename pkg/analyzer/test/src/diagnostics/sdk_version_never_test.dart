// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'sdk_constraint_verifier_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SdkVersionNeverTest);
  });
}

@reflectiveTest
class SdkVersionNeverTest extends SdkConstraintVerifierTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = new FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);

  @failingTest
  test_equals() async {
    // This test cannot pass because there is no version number that is equal to
    // when non-nullable was enabled.
    await verifyVersion('2.1.0', '''
Never sink;
''');
  }

  @failingTest
  test_greaterThan() async {
    // This test cannot pass because there is no version number that is equal to
    // when non-nullable was enabled.
    await verifyVersion('2.1.0', '''
Never sink;
''');
  }

  test_lessThan() async {
    await verifyVersion('2.3.0', '''
Never sink = (throw 42);
''', expectedErrors: [
      error(HintCode.SDK_VERSION_NEVER, 0, 5),
    ]);
  }
}
