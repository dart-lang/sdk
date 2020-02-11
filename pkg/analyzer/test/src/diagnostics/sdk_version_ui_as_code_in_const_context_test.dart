// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/dart/analysis/experiments.dart';
import 'package:analyzer/src/dart/error/hint_codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'sdk_constraint_verifier_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SdkVersionUiAsCodeInConstContextTest);
  });
}

@reflectiveTest
class SdkVersionUiAsCodeInConstContextTest extends SdkConstraintVerifierTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.fromEnableFlags(
      [EnableString.constant_update_2018],
    );

  test_equals() async {
    await verifyVersion('2.5.0', '''
const zero = [...const [0]];
''');
  }

  test_greaterThan() async {
    await verifyVersion('2.5.2', '''
const zero = [...const [0]];
''');
  }

  test_lessThan() async {
    await verifyVersion('2.4.0', '''
const zero = [if (0 < 1) 0];
''', expectedErrors: [
      error(HintCode.SDK_VERSION_UI_AS_CODE_IN_CONST_CONTEXT, 14, 12),
    ]);
  }
}
