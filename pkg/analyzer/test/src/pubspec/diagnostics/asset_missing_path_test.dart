// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssetMissingPathTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AssetMissingPathTest extends PubspecDiagnosticTest {
  test_assetHasPath() {
    newFile('/sample/assets/my_icon.png', '');
    assertDiagnostics('''
name: sample
flutter:
  assets:
    - path: assets/my_icon.png
      flavors:
        - premium
''');
  }

  test_assetMissingPath() {
    assertDiagnostics('''
name: sample
flutter:
  assets:
    - flavors:
// [diag.assetMissingPath][column 7][length 26] Asset map entry must contain a 'path' field.
        - premium
''');
  }
}
