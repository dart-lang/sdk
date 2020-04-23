// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../support/integration_tests.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SdkVersionAsyncExportedFromCoreIntegrationTest);
  });
}

@reflectiveTest
class SdkVersionAsyncExportedFromCoreIntegrationTest
    extends AbstractAnalysisServerIntegrationTest {
  Future<void> test_update_pubspec() async {
    var pubspecPath = sourcePath('pubspec.yaml');
    writeFile(pubspecPath, r'''
name: test
environment:
  sdk: ^2.0.0
''');

    var testPath = sourcePath('lib/test.dart');
    writeFile(testPath, '''
Future<int> zero() async => 0;
''');
    standardAnalysisSetup();

    // There is a hint with this SDK version constraint.
    await analysisFinished;
    expect(currentAnalysisErrors[testPath], hasLength(1));

    // 2.0.0 -> 2.1.0
    {
      writeFile(pubspecPath, r'''
name: test
environment:
  sdk: ^2.1.0
''');

      // The pubspec.yaml file change has been noticed and processed.
      // No more hints.
      await analysisFinished;
      expect(currentAnalysisErrors[testPath], isEmpty);
    }

    // 2.1.0 -> 2.0.0
    {
      writeFile(pubspecPath, r'''
name: test
environment:
  sdk: ^2.0.0
''');

      // The pubspec.yaml file change has been noticed and processed.
      // There is a hint again.
      await analysisFinished;
      expect(currentAnalysisErrors[testPath], hasLength(1));
    }
  }
}
