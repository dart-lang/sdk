// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../pubspec_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WorkspaceFieldTest);
  });
}

@reflectiveTest
class WorkspaceFieldTest extends PubspecDiagnosticTest {
  test_workspaceIsList() {
    assertErrors(
      '''
name: sample
workspace: package1
''',
      [diag.workspaceFieldNotList],
    );
  }

  test_workspaceValueIsNotString() {
    newFolder('/sample/package1');
    assertErrors(
      '''
name: sample
workspace:
    - 23
''',
      [diag.workspaceValueNotString],
    );
  }

  test_workspaceValueIsNotSubDirectory() {
    newFolder('/sample/package1');
    assertErrors(
      '''
name: sample
workspace:
    - /sample2
''',
      [diag.workspaceValueNotSubdirectory],
    );
  }

  test_workspaceValueIsString() {
    newFolder('/sample/package1');
    assertNoErrors('''
name: sample
workspace:
    - package1
''');
  }

  test_workspaceValueIsSubDirectory() {
    newFolder('/sample/package1');
    assertNoErrors('''
name: sample
workspace:
    - package1
''');
  }

  test_workspaceGlob_star_baseExists_noError() {
    newFolder('/sample/packages');
    assertNoErrors('''
name: sample
workspace:
  - packages/*
''');
  }

  test_workspaceGlob_questionMark_baseExists_noError() {
    newFolder('/sample/packages');
    assertNoErrors('''
name: sample
workspace:
  - packages/pkg?
''');
  }

  test_workspaceGlob_braces_baseExists_noError() {
    newFolder('/sample/packages');
    assertNoErrors('''
name: sample
workspace:
  - packages/{a,b}
''');
  }

  test_workspaceGlob_nestedBase_baseExists_noError() {
    newFolder('/sample/apps/nested');
    assertNoErrors('''
name: sample
workspace:
  - apps/nested/*
''');
  }

  test_workspaceGlob_baseMissing_error() {
    assertErrors(
      '''
name: sample
workspace:
  - packages/*
''',
      [diag.pathDoesNotExist],
    );
  }

  test_workspaceGlob_noBase_noError() {
    // Pattern starts with a glob character — no base directory to check.
    assertNoErrors('''
name: sample
workspace:
  - *
''');
  }
}
