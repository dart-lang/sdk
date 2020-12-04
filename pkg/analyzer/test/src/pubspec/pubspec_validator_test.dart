// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/pubspec/pubspec_validator.dart';
import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:yaml/yaml.dart';

import '../../generated/test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PubspecValidatorTest);
  });
}

@reflectiveTest
class PubspecValidatorTest with ResourceProviderMixin {
  PubspecValidator validator;

  /// Assert that when the validator is used on the given [content] the
  /// [expectedErrorCodes] are produced.
  void assertErrors(String content, List<ErrorCode> expectedErrorCodes) {
    YamlNode node = loadYamlNode(content);
    if (node is! YamlMap) {
      // The file is empty.
      node = YamlMap();
    }
    List<AnalysisError> errors = validator.validate((node as YamlMap).nodes);
    GatheringErrorListener listener = GatheringErrorListener();
    listener.addAll(errors);
    listener.assertErrorsWithCodes(expectedErrorCodes);
  }

  /// Assert that when the validator is used on the given [content] no errors
  /// are produced.
  void assertNoErrors(String content) {
    assertErrors(content, []);
  }

  void setUp() {
    File pubspecFile = getFile('/sample/pubspec.yaml');
    Source source = pubspecFile.createSource();
    validator = PubspecValidator(resourceProvider, source);
  }

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

  test_dependenciesField_empty() {
    assertNoErrors('''
name: sample
dependencies:
''');
  }

  test_dependenciesFieldNotMap_error_bool() {
    assertErrors('''
name: sample
dependencies: true
''', [PubspecWarningCode.DEPENDENCIES_FIELD_NOT_MAP]);
  }

  test_dependenciesFieldNotMap_noError() {
    assertNoErrors('''
name: sample
dependencies:
  a: any
''');
  }

  test_dependencyGit_malformed_empty() {
    // todo (pq): consider validating.
    assertNoErrors('''
name: sample
dependencies:
  foo:
    git:
''');
  }

  test_dependencyGit_malformed_list() {
    // todo (pq): consider validating.
    assertNoErrors('''
name: sample
dependencies:
  foo:
    git:
      - baz
''');
  }

  test_dependencyGit_malformed_scalar() {
    // todo (pq): consider validating.
    assertNoErrors('''
name: sample
dependencies:
  foo:
    git: baz
''');
  }

  test_dependencyGit_noVersion_valid() {
    assertNoErrors('''
name: sample
dependencies:
  foo:
    git:      
      url: git@github.com:foo/foo.git
      path: path/to/foo
''');
  }

  test_dependencyGit_version_error() {
    assertErrors('''
name: sample
version: 0.1.0
dependencies:
  foo:
    git:      
      url: git@github.com:foo/foo.git
      path: path/to/foo
''', [PubspecWarningCode.INVALID_DEPENDENCY]);
  }

  test_dependencyGit_version_valid() {
    assertNoErrors('''
name: sample
version: 0.1.0
publish_to: none
dependencies:
  foo:
    git:      
      url: git@github.com:foo/foo.git
      path: path/to/foo
''');
  }

  test_dependencyGitPath() {
    // git paths are not validated
    assertNoErrors('''
name: sample
dependencies:
  foo:
    git:
      url: git@github.com:foo/foo.git
      path: path/to/foo
''');
  }

  test_dependencyPath_malformed_empty() {
    // todo (pq): consider validating.
    assertNoErrors('''
name: sample
dependencies:
  foo:
    path:
''');
  }

  test_dependencyPath_malformed_list() {
    // todo (pq): consider validating.
    assertNoErrors('''
name: sample
dependencies:
  foo:
    path: 
     - baz
''');
  }

  test_dependencyPath_noVersion_valid() {
    newFolder('/foo');
    newFile('/foo/pubspec.yaml', content: '''
name: foo
''');
    assertNoErrors('''
name: sample
dependencies:
  foo:
    path: /foo
''');
  }

  test_dependencyPath_pubspecDoesNotExist() {
    newFolder('/foo');
    assertErrors('''
name: sample
dependencies:
  foo:
    path: /foo
''', [PubspecWarningCode.PATH_PUBSPEC_DOES_NOT_EXIST]);
  }

  test_dependencyPath_pubspecExists() {
    newFolder('/foo');
    newFile('/foo/pubspec.yaml', content: '''
name: foo
''');
    assertNoErrors('''
name: sample
dependencies:
  foo:
    path: /foo
''');
  }

  test_dependencyPath_valid_absolute() {
    newFolder('/foo');
    newFile('/foo/pubspec.yaml', content: '''
name: foo
''');
    assertNoErrors('''
name: sample
dependencies:
  foo:
    path: /foo
''');
  }

  test_dependencyPath_valid_relative() {
    newFolder('/foo');
    newFile('/foo/pubspec.yaml', content: '''
name: foo
''');
    assertNoErrors('''
name: sample
dependencies:
  foo:
    path: ../foo
''');
  }

  test_dependencyPath_version_error() {
    newFolder('/foo');
    newFile('/foo/pubspec.yaml', content: '''
name: foo
''');
    assertErrors('''
name: sample
version: 0.1.0
dependencies:
  foo:
    path: /foo
''', [PubspecWarningCode.INVALID_DEPENDENCY]);
  }

  test_dependencyPath_version_valid() {
    newFolder('/foo');
    newFile('/foo/pubspec.yaml', content: '''
name: foo
''');
    assertNoErrors('''
name: sample
version: 0.1.0
publish_to: none
dependencies:
  foo:
    path: /foo
''');
  }

  test_dependencyPathDoesNotExist_path_error() {
    assertErrors('''
name: sample
dependencies:
  foo:
    path: does/not/exist
''', [PubspecWarningCode.PATH_DOES_NOT_EXIST]);
  }

  test_devDependenciesField_empty() {
    assertNoErrors('''
name: sample
dev_dependencies:
''');
  }

  test_devDependenciesFieldNotMap_dev_error_bool() {
    assertErrors('''
name: sample
dev_dependencies: true
''', [PubspecWarningCode.DEPENDENCIES_FIELD_NOT_MAP]);
  }

  test_devDependenciesFieldNotMap_dev_noError() {
    assertNoErrors('''
name: sample
dev_dependencies:
  a: any
''');
  }

  test_devDependencyGit_version_no_error() {
    // Git paths are OK in dev_dependencies
    assertNoErrors('''
name: sample
version: 0.1.0
dev_dependencies:
  foo:
    git:      
      url: git@github.com:foo/foo.git
      path: path/to/foo
''');
  }

  test_devDependencyPathDoesNotExist_path_error() {
    assertErrors('''
name: sample
dev_dependencies:
  foo:
    path: does/not/exist
''', [PubspecWarningCode.PATH_DOES_NOT_EXIST]);
  }

  test_devDependencyPathExists() {
    newFolder('/foo');
    newFile('/foo/pubspec.yaml', content: '''
name: foo
''');
    assertNoErrors('''
name: sample
dev_dependencies:
  foo:
    path: /foo
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

  test_pathNotPosix_error() {
    newFolder('/foo');
    newFile('/foo/pubspec.yaml', content: '''
name: foo
''');
    assertErrors(r'''
name: sample
version: 0.1.0
publish_to: none
dependencies:
  foo:
    path: \foo
''', [
      PubspecWarningCode.PATH_NOT_POSIX,
    ]);
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
