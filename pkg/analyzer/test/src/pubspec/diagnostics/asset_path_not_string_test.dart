// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssetPathNotStringTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AssetPathNotStringTest extends PubspecDiagnosticTest {
  test_pathIsList() {
    assertDiagnostics('''
name: sample
flutter:
  assets:
    - path: [one, two, three]
//          ^^^^^^^^^^^^^^^^^
// [diag.assetPathNotString] Asset paths are required to be file paths (strings).
''');
  }

  test_pathIsNull() {
    assertDiagnostics('''
name: sample
flutter:
  assets:
    - path:
//        ^
// [diag.assetNotString][column 11][length 0] Assets are required to be file paths (strings).
''');
  }

  test_pathIsString() {
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
}
