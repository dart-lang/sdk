// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'driver_resolution.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportResolutionTest);
    defineReflectiveTests(ImportResolutionWithNnbdTest);
  });
}

@reflectiveTest
class ImportResolutionTest extends DriverResolutionTest {
  test_overrideCoreType_Never() async {
    newFile('/test/lib/declares_never.dart', content: '''
class Never {}
''');
    await assertNoErrorsInCode(r'''
import 'declares_never.dart';

Never f() => throw 'foo';
''');
  }
}

@reflectiveTest
class ImportResolutionWithNnbdTest extends ImportResolutionTest {
  @override
  AnalysisOptionsImpl get analysisOptions => AnalysisOptionsImpl()
    ..contextFeatures = FeatureSet.forTesting(
        sdkVersion: '2.3.0', additionalFeatures: [Feature.non_nullable]);
}
