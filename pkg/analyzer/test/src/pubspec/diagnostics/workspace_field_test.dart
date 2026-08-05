// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../dart/resolution/node_text_expectations.dart';
import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WorkspaceFieldTest);
    defineReflectiveTests(UpdateNodeTextExpectations);
  });
}

@reflectiveTest
class WorkspaceFieldTest extends PubspecDiagnosticTest {
  test_workspaceGlob_baseMissing_error() {
    assertDiagnostics('''
name: sample
workspace:
  - packages/*
//  ^^^^^^^^^^
// [diag.pathDoesNotExist] The path 'packages' doesn't exist.
''');
  }

  test_workspaceGlob_braces_baseExists_noError() {
    newFolder('/sample/packages');
    assertDiagnostics('''
name: sample
workspace:
  - packages/{a,b}
''');
  }

  test_workspaceGlob_nestedBase_baseExists_noError() {
    newFolder('/sample/apps/nested');
    assertDiagnostics('''
name: sample
workspace:
  - apps/nested/*
''');
  }

  test_workspaceGlob_noBase_noError() {
    // Pattern starts with a glob character — no base directory to check.
    assertDiagnostics('''
name: sample
workspace:
  - '*'
''');
  }

  test_workspaceGlob_questionMark_baseExists_noError() {
    newFolder('/sample/packages');
    assertDiagnostics('''
name: sample
workspace:
  - packages/pkg?
''');
  }

  test_workspaceGlob_star_baseExists_noError() {
    newFolder('/sample/packages');
    assertDiagnostics('''
name: sample
workspace:
  - packages/*
''');
  }

  test_workspaceIsList() {
    assertDiagnostics('''
name: sample
workspace: package1
//         ^^^^^^^^
// [diag.workspaceFieldNotList] The value of the 'workspace' field is required to be a list of relative file paths.
''');
  }

  test_workspaceValueIsNotString() {
    newFolder('/sample/package1');
    assertDiagnostics('''
name: sample
workspace:
    - 23
//    ^^
// [diag.workspaceValueNotString] Workspace entries are required to be directory paths (strings).
''');
  }

  test_workspaceValueIsNotSubDirectory() {
    newFolder('/sample/package1');
    assertDiagnostics('''
name: sample
workspace:
    - /sample2
//    ^^^^^^^^
// [diag.workspaceValueNotSubdirectory] Workspace values must be a relative path of a subdirectory of '/sample'.
''');
  }

  test_workspaceValueIsNull() {
    assertDiagnostics('''
name: sample
workspace:
    -
//  ^
// [diag.workspaceValueNotString][column 5][length 0] Workspace entries are required to be directory paths (strings).
''');
  }

  test_workspaceValueIsString() {
    newFolder('/sample/package1');
    assertDiagnostics('''
name: sample
workspace:
    - package1
''');
  }

  test_workspaceValueIsSubDirectory() {
    newFolder('/sample/package1');
    assertDiagnostics('''
name: sample
workspace:
    - package1
''');
  }
}
