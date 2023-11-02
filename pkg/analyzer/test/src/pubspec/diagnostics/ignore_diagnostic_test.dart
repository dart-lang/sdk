// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IgnoreDiagnosticTest);
  });
}

@reflectiveTest
class IgnoreDiagnosticTest extends PubspecDiagnosticTest {
  test_comma_separated() {
    assertErrors('''
name: sample
version: 0.1.0
dependencies:
  foo:
    # ignore: invalid_dependency, path_does_not_exist
    path: doesnt/exist
  bar:
    git: git@github.com:foo/bar.git
''', [PubspecWarningCode.INVALID_DEPENDENCY]);
  }

  test_file() {
    assertNoErrors('''
# ignore_for_file: invalid_dependency
name: sample
version: 0.1.0
dependencies:
  foo:
    git: git@github.com:foo/foo.git
  bar:
    git: git@github.com:foo/bar.git
''');
  }

  test_line_previous() {
    assertErrors('''
name: sample
version: 0.1.0
dependencies:
  foo:
    # ignore: invalid_dependency
    git: git@github.com:foo/foo.git
  bar:
    git: git@github.com:foo/bar.git
''', [PubspecWarningCode.INVALID_DEPENDENCY]);
  }

  test_line_same() {
    assertErrors('''
name: sample
version: 0.1.0
dependencies:
  foo:
    git: git@github.com:foo/foo.git
  bar:
    git: git@github.com:foo/bar.git # ignore: invalid_dependency
''', [PubspecWarningCode.INVALID_DEPENDENCY]);
  }

  test_noIgnores() {
    assertErrors('''
name: sample
version: 0.1.0
dependencies:
  foo:
    git: git@github.com:foo/foo.git
  bar:
    git: git@github.com:foo/bar.git
''', [
      PubspecWarningCode.INVALID_DEPENDENCY,
      PubspecWarningCode.INVALID_DEPENDENCY
    ]);
  }
}
