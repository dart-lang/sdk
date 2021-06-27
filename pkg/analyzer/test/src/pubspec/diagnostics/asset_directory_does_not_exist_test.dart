// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssetDirectoryDoesNotExistTest);
  });
}

@reflectiveTest
class AssetDirectoryDoesNotExistTest extends PubspecDiagnosticTest {
  test_assetDirectoryDoesExist_noError() {
    newFolder('/sample/assets/logos');
    assertNoErrors('''
name: sample
flutter:
  assets:
    - assets/logos/
''');
  }

  test_assetDirectoryDoesNotExist_error() {
    assertErrors('''
name: sample
flutter:
  assets:
    - assets/logos/
''', [PubspecWarningCode.ASSET_DIRECTORY_DOES_NOT_EXIST]);
  }
}
