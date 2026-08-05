// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssetDirectoryDoesNotExistTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AssetDirectoryDoesNotExistTest extends PubspecDiagnosticTest {
  test_assetDirectoryDoesExist_noError() {
    newFolder('/sample/assets/logos');
    assertDiagnostics('''
name: sample
flutter:
  assets:
    - assets/logos/
''');
  }

  test_assetDirectoryDoesNotExist_error() {
    assertDiagnostics('''
name: sample
flutter:
  assets:
    - assets/logos/
//    ^^^^^^^^^^^^^
// [diag.assetDirectoryDoesNotExist] The asset directory 'assets/logos/' doesn't exist.
''');
  }
}
