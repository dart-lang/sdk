// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/pubspec/pubspec_warning_code.dart';
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
      [PubspecWarningCode.workspaceFieldNotList],
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
      [PubspecWarningCode.workspaceValueNotString],
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
      [PubspecWarningCode.workspaceValueNotSubdirectory],
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
}
