// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssetNotStringOrMapTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AssetNotStringOrMapTest extends PubspecDiagnosticTest {
  test_assetNotString_error_int() {
    assertDiagnostics('''
name: sample
flutter:
  assets:
    - 23
//    ^^
// [diag.assetNotStringOrMap] An asset value is required to be a file path (string) or map.
''');
  }

  test_assetNotString_error_map() {
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

  test_assetNotString_error_null() {
    assertDiagnostics('''
name: sample
flutter:
  assets:
    -
//  ^
// [diag.assetNotStringOrMap][column 5][length 0] An asset value is required to be a file path (string) or map.
''');
  }

  test_assetNotString_noError() {
    newFile('/sample/assets/my_icon.png', '');
    assertDiagnostics('''
name: sample
flutter:
  assets:
    - assets/my_icon.png
''');
  }
}
