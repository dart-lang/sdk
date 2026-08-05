// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(InvalidDependencyTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class InvalidDependencyTest extends PubspecDiagnosticTest {
  test_dependencyGit_malformed_empty() {
    // TODO(pq): consider validating.
    assertDiagnostics('''
name: sample
dependencies:
  foo:
    git:
''');
  }

  test_dependencyGit_malformed_list() {
    // TODO(pq): consider validating.
    assertDiagnostics('''
name: sample
dependencies:
  foo:
    git:
      - baz
''');
  }

  test_dependencyGit_malformed_scalar() {
    // TODO(pq): consider validating.
    assertDiagnostics('''
name: sample
dependencies:
  foo:
    git: baz
''');
  }

  test_dependencyGit_noVersion_valid() {
    assertDiagnostics('''
name: sample
dependencies:
  foo:
    git:
      url: git@github.com:foo/foo.git
      path: path/to/foo
''');
  }

  test_dependencyGit_version_error() {
    assertDiagnostics('''
name: sample
version: 0.1.0
dependencies:
  foo:
    git:
//  ^^^
// [diag.invalidDependency] Publishable packages can't have 'git' dependencies.
      url: git@github.com:foo/foo.git
      path: path/to/foo
''');
  }

  test_dependencyGit_version_valid() {
    assertDiagnostics('''
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
    assertDiagnostics('''
name: sample
dependencies:
  foo:
    git:
      url: git@github.com:foo/foo.git
      path: path/to/foo
''');
  }

  test_dependencyPath_malformed_empty() {
    // TODO(pq): consider validating.
    assertDiagnostics('''
name: sample
dependencies:
  foo:
    path:
''');
  }

  test_dependencyPath_malformed_list() {
    // TODO(pq): consider validating.
    assertDiagnostics('''
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
    assertDiagnostics('''
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
    assertDiagnostics('''
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
    assertDiagnostics('''
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
    assertDiagnostics('''
name: sample
version: 0.1.0
dependencies:
  foo:
    path: /foo
//  ^^^^
// [diag.invalidDependency] Publishable packages can't have 'path' dependencies.
''');
  }

  test_dependencyPath_version_valid() {
    newFolder('/foo');
    newPubspecYamlFile('/foo', '''
name: foo
''');
    assertDiagnostics('''
name: sample
version: 0.1.0
publish_to: none
dependencies:
  foo:
    path: /foo
''');
  }

  test_devDependenciesField_empty() {
    assertDiagnostics('''
name: sample
dev_dependencies:
''');
  }

  test_devDependenciesFieldNotMap_dev_noError() {
    assertDiagnostics('''
name: sample
dev_dependencies:
  a: any
''');
  }

  test_devDependencyGit_version_no_error() {
    // Git paths are OK in dev_dependencies
    assertDiagnostics('''
name: sample
version: 0.1.0
dev_dependencies:
  foo:
    git:
      url: git@github.com:foo/foo.git
      path: path/to/foo
''');
  }
}
