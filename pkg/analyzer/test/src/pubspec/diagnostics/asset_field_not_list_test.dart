// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssetFieldNotListTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AssetFieldNotListTest extends PubspecDiagnosticTest {
  test_assetFieldNotList_error_empty() {
    assertDiagnostics('''
name: sample
flutter:
  assets:
//      ^
// [diag.assetFieldNotList][column 9][length 0] The value of the 'assets' field is expected to be a list of relative file paths.
''');
  }

  test_assetFieldNotList_error_string() {
    assertDiagnostics('''
name: sample
flutter:
  assets: assets/my_icon.png
//        ^^^^^^^^^^^^^^^^^^
// [diag.assetFieldNotList] The value of the 'assets' field is expected to be a list of relative file paths.
''');
  }

  test_assetFieldNotList_noError() {
    newFile('/sample/assets/my_icon.png', '');
    assertDiagnostics('''
name: sample
flutter:
  assets:
    - assets/my_icon.png
''');
  }
}
