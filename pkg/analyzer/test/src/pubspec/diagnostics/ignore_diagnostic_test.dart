// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(IgnoreDiagnosticTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class IgnoreDiagnosticTest extends PubspecDiagnosticTest {
  test_comma_separated() {
    assertDiagnostics('''
name: sample
version: 0.1.0
dependencies:
  foo:
    # ignore: invalid_dependency, path_does_not_exist
    path: doesnt/exist
  bar:
    git: git@github.com:foo/bar.git
//  ^^^
// [diag.invalidDependency] Publishable packages can't have 'git' dependencies.
''');
  }

  test_file() {
    assertDiagnostics('''
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
    assertDiagnostics('''
name: sample
version: 0.1.0
dependencies:
  foo:
    # ignore: invalid_dependency
    git: git@github.com:foo/foo.git
  bar:
    git: git@github.com:foo/bar.git
//  ^^^
// [diag.invalidDependency] Publishable packages can't have 'git' dependencies.
''');
  }

  test_line_same() {
    assertDiagnostics('''
name: sample
version: 0.1.0
dependencies:
  foo:
    git: git@github.com:foo/foo.git
//  ^^^
// [diag.invalidDependency] Publishable packages can't have 'git' dependencies.
  bar:
    git: git@github.com:foo/bar.git # ignore: invalid_dependency
''');
  }

  test_noIgnores() {
    assertDiagnostics('''
name: sample
version: 0.1.0
dependencies:
  foo:
    git: git@github.com:foo/foo.git
//  ^^^
// [diag.invalidDependency] Publishable packages can't have 'git' dependencies.
  bar:
    git: git@github.com:foo/bar.git
//  ^^^
// [diag.invalidDependency] Publishable packages can't have 'git' dependencies.
''');
  }
}
