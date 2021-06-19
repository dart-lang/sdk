// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PubspecDependencyValidatorTest);
  });
}

@reflectiveTest
class PubspecDependencyValidatorTest extends BasePubspecValidatorTest {
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
    newPubspecYamlFile('/foo', '''
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
    newPubspecYamlFile('/foo', '''
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
    newPubspecYamlFile('/foo', '''
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
    newPubspecYamlFile('/foo', '''
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
    newPubspecYamlFile('/foo', '''
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
    newPubspecYamlFile('/foo', '''
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
    newPubspecYamlFile('/foo', '''
name: foo
''');
    assertNoErrors('''
name: sample
dev_dependencies:
  foo:
    path: /foo
''');
  }

  test_pathNotPosix_error() {
    newFolder('/foo');
    newPubspecYamlFile('/foo', '''
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
