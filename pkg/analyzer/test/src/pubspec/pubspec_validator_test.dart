// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

import '../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PubspecValidatorTest);
  });
}

@reflectiveTest
class PubspecValidatorTest {
  MemoryResourceProvider provider;
  PubspecValidator validator;

  /**
   * Assert that when the validator is used on the given [content] the
   * [expectedErrorCodes] are produced.
   */
  void assertErrors(String content, List<ErrorCode> expectedErrorCodes) {
    YamlNode node = loadYamlNode(content);
    if (node is! YamlMap) {
      // The file is empty.
      node = new YamlMap();
    }
    List<AnalysisError> errors = validator.validate((node as YamlMap).nodes);
    GatheringErrorListener listener = new GatheringErrorListener();
    listener.addAll(errors);
    listener.assertErrorsWithCodes(expectedErrorCodes);
  }

  /**
   * Assert that when the validator is used on the given [content] no errors are
   * produced.
   */
  void assertNoErrors(String content) {
    assertErrors(content, []);
  }

  void setUp() {
    provider = new MemoryResourceProvider();
    File pubspecFile = provider.getFile('/sample/pubspec.yaml');
    Source source = pubspecFile.createSource();
    validator = new PubspecValidator(provider, source);
  }

  test_assetDoesNotExist_error() {
    assertErrors('''
name: sample
flutter:
  assets:
    - assets/my_icon.png
''', [PubspecWarningCode.ASSET_DOES_NOT_EXIST]);
  }

  test_assetDoesNotExist_noError() {
    provider.newFile('/sample/assets/my_icon.png', '');
    assertNoErrors('''
name: sample
flutter:
  assets:
    - assets/my_icon.png
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
    provider.newFile('/sample/assets/my_icon.png', '');
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
    provider.newFile('/sample/assets/my_icon.png', '');
    assertNoErrors('''
name: sample
flutter:
  assets:
    - assets/my_icon.png
''');
  }

  test_dependenciesFieldNotMap_dev_error_bool() {
    assertErrors('''
name: sample
dev_dependencies: true
''', [PubspecWarningCode.DEPENDENCIES_FIELD_NOT_MAP]);
  }

  test_dependenciesFieldNotMap_dev_error_empty() {
    assertErrors('''
name: sample
dev_dependencies:
''', [PubspecWarningCode.DEPENDENCIES_FIELD_NOT_MAP]);
  }

  test_dependenciesFieldNotMap_dev_noError() {
    assertNoErrors('''
name: sample
dev_dependencies:
  a: any
''');
  }

  test_dependenciesFieldNotMap_error_bool() {
    assertErrors('''
name: sample
dependencies: true
''', [PubspecWarningCode.DEPENDENCIES_FIELD_NOT_MAP]);
  }

  test_dependenciesFieldNotMap_error_empty() {
    assertErrors('''
name: sample
dependencies:
''', [PubspecWarningCode.DEPENDENCIES_FIELD_NOT_MAP]);
  }

  test_dependenciesFieldNotMap_noError() {
    assertNoErrors('''
name: sample
dependencies:
  a: any
''');
  }

  test_flutterFieldNotMap_error_bool() {
    assertErrors('''
name: sample
flutter: true
''', [PubspecWarningCode.FLUTTER_FIELD_NOT_MAP]);
  }

  test_flutterFieldNotMap_error_empty() {
    assertErrors('''
name: sample
flutter:
''', [PubspecWarningCode.FLUTTER_FIELD_NOT_MAP]);
  }

  test_flutterFieldNotMap_noError() {
    provider.newFile('/sample/assets/my_icon.png', '');
    assertNoErrors('''
name: sample
flutter:
  assets:
    - assets/my_icon.png
''');
  }

  test_missingName_error() {
    assertErrors('', [PubspecWarningCode.MISSING_NAME]);
  }

  test_missingName_noError() {
    assertNoErrors('''
name: sample
''');
  }

  test_nameNotString_error_int() {
    assertErrors('''
name: 42
''', [PubspecWarningCode.NAME_NOT_STRING]);
  }

  test_nameNotString_noError() {
    assertNoErrors('''
name: sample
''');
  }

  test_unnecessaryDevDependency_error() {
    assertErrors('''
name: sample
dependencies:
  a: any
dev_dependencies:
  a: any
''', [PubspecWarningCode.UNNECESSARY_DEV_DEPENDENCY]);
  }

  test_unnecessaryDevDependency_noError() {
    assertNoErrors('''
name: sample
dependencies:
  a: any
dev_dependencies:
  b: any
''');
  }
}
