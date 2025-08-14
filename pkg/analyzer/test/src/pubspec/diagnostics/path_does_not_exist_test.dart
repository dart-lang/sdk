// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(PathDoesNotExistTest);
  });
}

@reflectiveTest
class PathDoesNotExistTest extends PubspecDiagnosticTest {
  test_dependencyPathDoesNotExist_path_error() {
    assertErrors(
      '''
name: sample
dependencies:
  foo:
    path: does/not/exist
''',
      [PubspecWarningCode.pathDoesNotExist],
    );
  }

  test_devDependencyPathDoesNotExist_path_error() {
    assertErrors(
      '''
name: sample
dev_dependencies:
  foo:
    path: does/not/exist
''',
      [PubspecWarningCode.pathDoesNotExist],
    );
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

  test_screenshotPathDoesNotExist_path_error() {
    assertErrors(
      '''
name: foo
screenshots:
  - description: '...'
    path: example/screenshots/no.webp
''',
      [PubspecWarningCode.pathDoesNotExist],
    );
  }

  test_screenshotPathDoesNotExist_path_error_multiple() {
    assertErrors(
      '''
name: foo
screenshots:
  - description: '...'
    path: example/screenshots/no.webp
  - description: '...'
    path: example/screenshots/no.webp
''',
      [
        PubspecWarningCode.pathDoesNotExist,
        PubspecWarningCode.pathDoesNotExist,
      ],
    );
  }

  test_screenshotPathExists() {
    newFolder('/sample/example');
    newFile('/sample/example/yes.webp', '');
    assertNoErrors('''
name: foo
screenshots:
  - description: '...'
    path: example/yes.webp
''');
  }
}
