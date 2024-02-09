// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssetNotStringOrMapTest);
  });
}

@reflectiveTest
class AssetNotStringOrMapTest extends PubspecDiagnosticTest {
  test_assetNotString_error_int() {
    assertErrors('''
name: sample
flutter:
  assets:
    - 23
''', [PubspecWarningCode.ASSET_NOT_STRING_OR_MAP]);
  }

  test_assetNotString_error_map() {
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

  test_assetNotString_noError() {
    newFile('/sample/assets/my_icon.png', '');
    assertNoErrors('''
name: sample
flutter:
  assets:
    - assets/my_icon.png
''');
  }
}
