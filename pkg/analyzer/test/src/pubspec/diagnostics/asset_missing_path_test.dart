// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssetMissingPathTest);
  });
}

@reflectiveTest
class AssetMissingPathTest extends PubspecDiagnosticTest {
  test_assetHasPath() {
    newFile('/sample/assets/my_icon.png', '');
    assertNoErrors('''
name: sample
flutter:
  assets:
    - path: assets/my_icon.png
      flavors:
        - premium
''');
  }

  test_assetMissingPath() {
    assertErrors('''
name: sample
flutter:
  assets:
    - flavors:
        - premium
''', [PubspecWarningCode.ASSET_MISSING_PATH]);
  }
}
