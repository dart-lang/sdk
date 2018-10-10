// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_refactoring.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MoveFileTest);
  });
}

@reflectiveTest
class MoveFileTest extends RefactoringTest {
  MoveFileRefactoring refactoring;

  @failingTest
  test_dart_uris_are_unmodified() async {
    // TODO(dantup): See _computeNewUri implementation which currently only
    // handles relative + package: urls (package url handling is also incomplete)
    fail('Not yet implemented/tested');
  }

  test_file_containing_imports_exports_parts() async {
    String pathA = '/project/000/1111/a.dart';
    String pathB = '/project/000/1111/b.dart';
    String pathC = '/project/000/1111/22/c.dart';
    testFile = '/project/000/1111/test.dart';
    addSource('/absolute/uri.dart', '');
    addSource(pathA, 'part of lib;');
    addSource(pathB, "import 'test.dart';");
    addSource(pathC, '');
    addTestSource('''
library lib;
import 'dart:math';
import '22/c.dart';
export '333/d.dart';
part 'a.dart';
part '${convertAbsolutePathToUri('/absolute/uri.dart')}';
''');
    // perform refactoring
    _createRefactoring('/project/000/1111/22/new_name.dart');
    await _assertSuccessfulRefactoring();
    assertNoFileChange(pathA);
    assertFileChangeResult(pathB, "import '22/new_name.dart';");
    assertNoFileChange(pathC);
    assertFileChangeResult(testFile, '''
library lib;
import 'dart:math';
import 'c.dart';
export '../333/d.dart';
part '../a.dart';
part '${convertAbsolutePathToUri('/absolute/uri.dart')}';
''');
  }

  test_file_importedLibrary_down() async {
    String pathA = '/project/000/1111/a.dart';
    testFile = '/project/000/1111/test.dart';
    addSource(pathA, '''
import 'test.dart';
''');
    addTestSource('');
    // perform refactoring
    _createRefactoring('/project/000/1111/22/new_name.dart');
    await _assertSuccessfulRefactoring();
    assertFileChangeResult(pathA, '''
import '22/new_name.dart';
''');
    assertNoFileChange(testFile);
  }

  test_file_importedLibrary_sideways() async {
    String pathA = '/project/000/1111/a.dart';
    testFile = '/project/000/1111/sub/folder/test.dart';
    addSource(pathA, '''
import 'sub/folder/test.dart';
''');
    addTestSource('');
    // perform refactoring
    _createRefactoring('/project/000/new/folder/name/new_name.dart');
    await _assertSuccessfulRefactoring();
    assertFileChangeResult(pathA, '''
import '../new/folder/name/new_name.dart';
''');
    assertNoFileChange(testFile);
  }

  test_file_importedLibrary_up() async {
    String pathA = '/project/000/1111/a.dart';
    testFile = '/project/000/1111/22/test.dart';
    addSource(pathA, '''
import '22/test.dart';
''');
    addTestSource('');
    // perform refactoring
    _createRefactoring('/project/000/1111/new_name.dart');
    await _assertSuccessfulRefactoring();
    assertFileChangeResult(pathA, '''
import 'new_name.dart';
''');
    assertNoFileChange(testFile);
  }

  @failingTest
  test_file_referenced_by_multiple_libraries() async {
    // This test fails because the search index doesn't support multiple uris for
    // a library, so only one of them is updated.
    String pathA = '/project/000/1111/a.dart';
    String pathB = '/project/000/b.dart';
    testFile = '/project/000/1111/22/test.dart';
    addSource(pathA, '''
library lib;
part '22/test.dart';
''');
    addSource(pathB, '''
library lib;
part '1111/22/test.dart';
''');
    addTestSource('''
part of lib;
''');
    // perform refactoring
    _createRefactoring('/project/000/1111/22/new_name.dart');
    await _assertSuccessfulRefactoring();
    assertFileChangeResult(pathA, '''
library lib;
part '22/new_name.dart';
''');
    assertFileChangeResult(pathB, '''
library lib;
part '1111/22/new_name.dart';
''');
    assertNoFileChange(testFile);
  }

  test_file_referenced_by_part() async {
    String pathA = '/project/000/1111/a.dart';
    testFile = '/project/000/1111/22/test.dart';
    addSource(pathA, '''
library lib;
part '22/test.dart';
''');
    addTestSource('''
part of lib;
''');
    // perform refactoring
    _createRefactoring('/project/000/1111/22/new_name.dart');
    await _assertSuccessfulRefactoring();
    assertFileChangeResult(pathA, '''
library lib;
part '22/new_name.dart';
''');
    assertNoFileChange(testFile);
  }

  @failingTest
  test_folder_inside_project() async {
    fail('Not yet implemented/tested');
  }

  test_folder_outside_workspace_returns_failure() async {
    _createRefactoring('/tmp-new', oldName: '/tmp');
    // TODO(dantup): These paths should all use convertPath so they're as expected
    // on Windows.
    await _assertFailedRefactoring(RefactoringProblemSeverity.FATAL,
        expectedMessage:
            '${convertPath('/tmp')} does not belong to an analysis root.');
  }

  test_nonexistent_file_returns_failure() async {
    _createRefactoring(convertPath('/project/test_missing_new.dart'),
        oldName: convertPath('/project/test_missing.dart'));
    await _assertFailedRefactoring(RefactoringProblemSeverity.FATAL,
        expectedMessage:
            '${convertPath('/project/test_missing.dart')} does not exist.');
  }

  @failingTest
  test_project_folder_ancestor() async {
    // For this, we need the project to not be at top level (/project) so we can
    // rename an ancestor folder.
    fail('Not yet implemented/tested');
  }

  test_projectFolder() async {
    _createRefactoring('/project2', oldName: '/project');
    await _assertFailedRefactoring(RefactoringProblemSeverity.FATAL,
        expectedMessage:
            'Renaming an analysis root is not supported (${convertPath('/project')})');
  }

  test_renaming_part_that_uses_uri_in_part_of() async {
    // If the file is a part in a library, and the part-of directive uses a URI
    // rather than a library name, that will need updating too (if the relative
    // path to the parent changes).
    String pathA = '/project/000/1111/a.dart';
    testFile = '/project/000/1111/22/test.dart';
    addSource(pathA, '''
library lib;
part '22/test.dart';
''');
    addTestSource('''
part of '../a.dart';
''');
    // perform refactoring
    _createRefactoring('/project/000/1111/22/33/test.dart');
    await _assertSuccessfulRefactoring();
    assertFileChangeResult(pathA, '''
library lib;
part '22/33/test.dart';
''');
    assertFileChangeResult(testFile, '''
part of '../../a.dart';
''');
  }

  /**
   * Checks that all conditions are OK.
   */
  Future _assertSuccessfulRefactoring() async {
    await assertRefactoringConditionsOK();
    refactoringChange = await refactoring.createChange();
  }

  void _createRefactoring(String newName, {String oldName}) {
    var workspace = new RefactoringWorkspace([driver], searchEngine);
    // Allow passing an oldName for when we don't want to rename testSource,
    // but otherwise fall back to that.
    if (oldName != null) {
      refactoring = new MoveFileRefactoring(
          resourceProvider, workspace, null, convertPath(oldName));
    } else {
      refactoring = new MoveFileRefactoring(
          resourceProvider, workspace, testSource, null);
    }
    refactoring.newFile = convertPath(newName);
  }

  Future _assertFailedRefactoring(RefactoringProblemSeverity expectedSeverity,
      {String expectedMessage}) async {
    RefactoringStatus status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, expectedSeverity,
        expectedMessage: expectedMessage);
  }
}
