// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AssetDoesNotExistTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class AssetDoesNotExistTest extends PubspecDiagnosticTest {
  test_assetDoesNotExist_path_error() {
    assertDiagnostics('''
name: sample
flutter:
  assets:
    - assets/my_icon.png
//    ^^^^^^^^^^^^^^^^^^
// [diag.assetDoesNotExist] The asset file 'assets/my_icon.png' doesn't exist.
''');
  }

  test_assetDoesNotExist_path_inRoot_noError() {
    newFile('/sample/assets/my_icon.png', '');
    assertDiagnostics('''
name: sample
flutter:
  assets:
    - assets/my_icon.png
''');
  }

  test_assetDoesNotExist_path_inSubdir_noError() {
    newFile('/sample/assets/images/2.0x/my_icon.png', '');
    assertDiagnostics('''
name: sample
flutter:
  assets:
    - assets/images/my_icon.png
''');
  }

  // TODO(scheglov): Support package assets.
  @failingTest
  test_assetDoesNotExist_uri_error() {
    assertDiagnostics('''
name: sample
flutter:
  assets:
    - packages/icons/my_icon.png
//    ^^^^^^^^^^^^^^^^^^^^^^^^^^
// [diag.assetDoesNotExist] The asset file 'packages/icons/my_icon.png' doesn't exist.
''');
  }

  test_assetDoesNotExist_uri_noError() {
    // TODO(brianwilkerson): Create a package named `icons` that contains the
    // referenced file, and a `.packages` file that references that package.
    assertDiagnostics('''
name: sample
flutter:
  assets:
    - packages/icons/my_icon.png
''');
  }
}
