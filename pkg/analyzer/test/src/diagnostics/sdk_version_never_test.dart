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
    defineReflectiveTests(SdkVersionNeverWithNnbdTest);
  });
}

@reflectiveTest
class SdkVersionNeverTest extends SdkConstraintVerifierTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(sdkVersion: '2.7.0');

  test_languageVersionBeforeNullSafety() async {
    await verifyVersion('2.7.0', r'''
Never foo;
''', expectedErrors: [
      error(HintCode.SDK_VERSION_NEVER, 0, 5),
    ]);
  }
}

@reflectiveTest
class SdkVersionNeverWithNnbdTest extends SdkConstraintVerifierTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures =
        FeatureSet.forTesting(additionalFeatures: [Feature.non_nullable]);

  test_experimentEnabled() async {
    await verifyVersion('2.7.0', r'''
Never foo = (throw 42);
''');
  }

  test_experimentEnabled_libraryOptedOut() async {
    await verifyVersion('2.7.0', r'''
// @dart = 2.7
Never foo = (throw 42);
''', expectedErrors: [
      error(HintCode.SDK_VERSION_NEVER, 15, 5),
    ]);
  }
}
