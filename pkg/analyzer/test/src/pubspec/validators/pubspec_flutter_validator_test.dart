// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PubspecFlutterValidatorTest);
  });
}

@reflectiveTest
class PubspecFlutterValidatorTest extends BasePubspecValidatorTest {
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

  test_assetDoesNotExist_path_error() {
    assertErrors('''
name: sample
flutter:
  assets:
    - assets/my_icon.png
''', [PubspecWarningCode.ASSET_DOES_NOT_EXIST]);
  }

  test_assetDoesNotExist_path_inRoot_noError() {
    newFile('/sample/assets/my_icon.png');
    assertNoErrors('''
name: sample
flutter:
  assets:
    - assets/my_icon.png
''');
  }

  test_assetDoesNotExist_path_inSubdir_noError() {
    newFile('/sample/assets/images/2.0x/my_icon.png');
    assertNoErrors('''
name: sample
flutter:
  assets:
    - assets/images/my_icon.png
''');
  }

  @failingTest
  test_assetDoesNotExist_uri_error() {
    assertErrors('''
name: sample
flutter:
  assets:
    - packages/icons/my_icon.png
''', [PubspecWarningCode.ASSET_DOES_NOT_EXIST]);
  }

  test_assetDoesNotExist_uri_noError() {
    // TODO(brianwilkerson) Create a package named `icons` that contains the
    // referenced file, and a `.packages` file that references that package.
    assertNoErrors('''
name: sample
flutter:
  assets:
    - packages/icons/my_icon.png
''');
  }

  test_assetFieldNotList_error_empty() {
    assertErrors('''
name: sample
flutter:
  assets:
''', [PubspecWarningCode.ASSET_FIELD_NOT_LIST]);
  }

  test_assetFieldNotList_error_string() {
    assertErrors('''
name: sample
flutter:
  assets: assets/my_icon.png
''', [PubspecWarningCode.ASSET_FIELD_NOT_LIST]);
  }

  test_assetFieldNotList_noError() {
    newFile('/sample/assets/my_icon.png');
    assertNoErrors('''
name: sample
flutter:
  assets:
    - assets/my_icon.png
''');
  }

  test_assetNotString_error_int() {
    assertErrors('''
name: sample
flutter:
  assets:
    - 23
''', [PubspecWarningCode.ASSET_NOT_STRING]);
  }

  test_assetNotString_error_map() {
    assertErrors('''
name: sample
flutter:
  assets:
    - my_icon:
      default: assets/my_icon.png
      large: assets/large/my_icon.png
''', [PubspecWarningCode.ASSET_NOT_STRING]);
  }

  test_assetNotString_noError() {
    newFile('/sample/assets/my_icon.png');
    assertNoErrors('''
name: sample
flutter:
  assets:
    - assets/my_icon.png
''');
  }

  test_flutterField_empty_noError() {
    assertNoErrors('''
name: sample
flutter:
''');

    assertNoErrors('''
name: sample
flutter:

''');
  }

  test_flutterFieldNotMap_error_bool() {
    assertErrors('''
name: sample
flutter: true
''', [PubspecWarningCode.FLUTTER_FIELD_NOT_MAP]);
  }

  test_flutterFieldNotMap_noError() {
    newFile('/sample/assets/my_icon.png');
    assertNoErrors('''
name: sample
flutter:
  assets:
    - assets/my_icon.png
''');
  }
}
