// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_refactoring.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MoveFileTest);
  });
}

@reflectiveTest
class MoveFileTest extends RefactoringTest {
  @override
  MoveFileRefactoring refactoring;

  Future<void> test_file_containing_imports_exports_parts() async {
    var pathA = convertPath('/home/test/000/1111/a.dart');
    var pathB = convertPath('/home/test/000/1111/b.dart');
    var pathC = convertPath('/home/test/000/1111/22/c.dart');
    testFile = convertPath('/home/test/000/1111/test.dart');
    addSource('/absolute/uri.dart', '');
    addSource(pathA, 'part of lib;');
    addSource(pathB, "import 'test.dart';");
    addSource(pathC, '');
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
library lib;
import 'dart:math';
import '22/c.dart';
export '333/d.dart';
part 'a.dart';
part '${toUriStr('/absolute/uri.dart')}';
''');
    await analyzeTestPackageFiles();
    // perform refactoring
    _createRefactoring('/home/test/000/1111/22/new_name.dart');
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
part '${toUriStr('/absolute/uri.dart')}';
''');
  }

  Future<void> test_file_imported_with_package_uri_down() async {
    var file = newFile('/home/test/lib/old_name.dart', content: '');
    addTestSource(r'''
import 'package:test/old_name.dart';
''');
    await analyzeTestPackageFiles();

    // Since the file being refactored isn't the test source, we set the
    // testAnalysisResult manually here, the path is referenced through the
    // referenced File object to run on Windows:
    testAnalysisResult = await session.getResolvedUnit(file.path);

    _createRefactoring('/home/test/lib/222/new_name.dart', oldFile: file.path);
    await _assertSuccessfulRefactoring();

    assertFileChangeResult(testFile, '''
import 'package:test/222/new_name.dart';
''');
  }

  @failingTest
  Future<void> test_file_imported_with_package_uri_lib_change() async {
    // The current testing stack does not support creating such bazel roots
    var file =
        newFile('/home/test0/test1/test2/lib/111/name.dart', content: '');
    addTestSource(r'''
import 'package:test0.test1.test2/111/name.dart';
''');

    // Since the file being refactored isn't the test source, we set the
    // testAnalysisResult manually here, the path is referenced through the
    // referenced File object to run on Windows:
    testAnalysisResult = await session.getResolvedUnit(file.path);

    _createRefactoring('/home/test0/test1/test3/lib/111/name.dart',
        oldFile: file.path);
    await _assertSuccessfulRefactoring();

    assertFileChangeResult(testFile, '''
import 'package:test0.test1.test3/111/name.dart';
''');
  }

  @failingTest
  Future<void> test_file_imported_with_package_uri_lib_change_down() async {
    // The current testing stack does not support creating such bazel roots
    var file =
        newFile('/home/test0/test1/test2/lib/111/name.dart', content: '');
    addTestSource(r'''
import 'package:test0.test1.test2/111/name.dart';
''');

    // Since the file being refactored isn't the test source, we set the
    // testAnalysisResult manually here, the path is referenced through the
    // referenced File object to run on Windows:
    testAnalysisResult = await session.getResolvedUnit(file.path);

    _createRefactoring('/home/test0/test1/test2/test3/lib/111/name.dart',
        oldFile: file.path);
    await _assertSuccessfulRefactoring();

    assertFileChangeResult(testFile, '''
import 'package:test0.test1.test2.test3/111/name.dart';
''');
  }

  @failingTest
  Future<void> test_file_imported_with_package_uri_lib_change_up() async {
    // The current testing stack does not support creating such bazel roots
    var file =
        newFile('/home/test0/test1/test2/lib/111/name.dart', content: '');
    addTestSource(r'''
import 'package:test0.test1.test2/111/name.dart';
''');

    // Since the file being refactored isn't the test source, we set the
    // testAnalysisResult manually here, the path is referenced through the
    // referenced File object to run on Windows:
    testAnalysisResult = await session.getResolvedUnit(file.path);

    _createRefactoring('/home/test0/test1/lib/111/name.dart',
        oldFile: file.path);
    await _assertSuccessfulRefactoring();

    assertFileChangeResult(testFile, '''
import 'package:test0.test1/111/name.dart';
''');
  }

  Future<void> test_file_imported_with_package_uri_sideways() async {
    var file = newFile('/home/test/lib/111/old_name.dart', content: '');
    addTestSource(r'''
import 'package:test/111/old_name.dart';
''');
    await analyzeTestPackageFiles();

    // Since the file being refactored isn't the test source, we set the
    // testAnalysisResult manually here, the path is referenced through the
    // referenced File object to run on Windows:
    testAnalysisResult = await session.getResolvedUnit(file.path);

    _createRefactoring('/home/test/lib/222/new_name.dart', oldFile: file.path);
    await _assertSuccessfulRefactoring();

    assertFileChangeResult(testFile, '''
import 'package:test/222/new_name.dart';
''');
  }

  Future<void> test_file_imported_with_package_uri_up() async {
    var file = newFile('/home/test/lib/222/old_name.dart', content: '');
    addTestSource(r'''
import 'package:test/222/old_name.dart';
''');
    await analyzeTestPackageFiles();

    // Since the file being refactored isn't the test source, we set the
    // testAnalysisResult manually here, the path is referenced through the
    // referenced File object to run on Windows:
    testAnalysisResult = await session.getResolvedUnit(file.path);

    _createRefactoring('/home/test/lib/new_name.dart', oldFile: file.path);
    await _assertSuccessfulRefactoring();

    assertFileChangeResult(testFile, '''
import 'package:test/new_name.dart';
''');
  }

  Future<void> test_file_imported_with_relative_uri_down() async {
    var pathA = convertPath('/home/test/000/1111/a.dart');
    testFile = convertPath('/home/test/000/1111/test.dart');
    addSource(pathA, '''
import 'test.dart';
''');
    await analyzeTestPackageFiles();
    await resolveTestCode('');

    // perform refactoring
    _createRefactoring('/home/test/000/1111/22/new_name.dart');
    await _assertSuccessfulRefactoring();

    assertFileChangeResult(pathA, '''
import '22/new_name.dart';
''');
    assertNoFileChange(testFile);
  }

  Future<void> test_file_imported_with_relative_uri_sideways() async {
    var pathA = convertPath('/home/test/000/1111/a.dart');
    testFile = convertPath('/home/test/000/1111/sub/folder/test.dart');
    addSource(pathA, '''
import 'sub/folder/test.dart';
''');
    await analyzeTestPackageFiles();
    await resolveTestCode('');
    // perform refactoring
    _createRefactoring('/home/test/000/new/folder/name/new_name.dart');
    await _assertSuccessfulRefactoring();
    assertFileChangeResult(pathA, '''
import '../new/folder/name/new_name.dart';
''');
    assertNoFileChange(testFile);
  }

  Future<void> test_file_imported_with_relative_uri_up() async {
    var pathA = convertPath('/home/test/000/1111/a.dart');
    testFile = convertPath('/home/test/000/1111/22/test.dart');
    addSource(pathA, '''
import '22/test.dart';
''');
    await analyzeTestPackageFiles();
    await resolveTestCode('');
    // perform refactoring
    _createRefactoring('/home/test/000/1111/new_name.dart');
    await _assertSuccessfulRefactoring();
    assertFileChangeResult(pathA, '''
import 'new_name.dart';
''');
    assertNoFileChange(testFile);
  }

  @failingTest
  Future<void> test_file_referenced_by_multiple_libraries() async {
    // This test fails because the search index doesn't support multiple uris for
    // a library, so only one of them is updated.
    var pathA = convertPath('/home/test/000/1111/a.dart');
    var pathB = convertPath('/home/test/000/b.dart');
    testFile = convertPath('/home/test/000/1111/22/test.dart');
    addSource(pathA, '''
library lib;
part '22/test.dart';
''');
    addSource(pathB, '''
library lib;
part '1111/22/test.dart';
''');
    await resolveTestCode('''
part of lib;
''');
    // perform refactoring
    _createRefactoring('/home/test/000/1111/22/new_name.dart');
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

  Future<void> test_file_referenced_by_part() async {
    var pathA = convertPath('/home/test/000/1111/a.dart');
    testFile = convertPath('/home/test/000/1111/22/test.dart');
    addSource(pathA, '''
library lib;
part '22/test.dart';
''');
    addTestSource('''
part of lib;
''');
    await analyzeTestPackageFiles();
    await resolveTestFile();
    // perform refactoring
    _createRefactoring('/home/test/000/1111/22/new_name.dart');
    await _assertSuccessfulRefactoring();
    assertFileChangeResult(pathA, '''
library lib;
part '22/new_name.dart';
''');
    assertNoFileChange(testFile);
  }

  @failingTest
  Future<void> test_folder_inside_project() async {
    fail('Not yet implemented/tested');
  }

  Future<void> test_folder_outside_workspace_returns_failure() async {
    _createRefactoring('/tmp-new', oldFile: '/tmp');
    // TODO(dantup): These paths should all use convertPath so they're as expected
    // on Windows.
    await _assertFailedRefactoring(RefactoringProblemSeverity.FATAL,
        expectedMessage:
            '${convertPath('/tmp')} does not belong to an analysis root.');
  }

  Future<void> test_nonexistent_file_returns_failure() async {
    _createRefactoring(convertPath('/home/test/test_missing_new.dart'),
        oldFile: convertPath('/home/test/test_missing.dart'));
    await _assertFailedRefactoring(RefactoringProblemSeverity.FATAL,
        expectedMessage:
            '${convertPath('/home/test/test_missing.dart')} does not exist.');
  }

  @failingTest
  Future<void> test_project_folder_ancestor() async {
    // For this, we need the project to not be at top level (/project) so we can
    // rename an ancestor folder.
    fail('Not yet implemented/tested');
  }

  Future<void> test_projectFolder() async {
    _createRefactoring('/home/test2', oldFile: '/home/test');
    await _assertFailedRefactoring(RefactoringProblemSeverity.FATAL,
        expectedMessage: 'Renaming an analysis root is not supported '
            '(${convertPath('/home/test')})');
  }

  Future<void> test_renaming_part_that_uses_uri_in_part_of() async {
    // If the file is a part in a library, and the part-of directive uses a URI
    // rather than a library name, that will need updating too (if the relative
    // path to the parent changes).
    var pathA = convertPath('/home/test/000/1111/a.dart');
    testFile = convertPath('/home/test/000/1111/22/test.dart');
    addSource(pathA, '''
library lib;
part '22/test.dart';
''');
    addTestSource('''
part of '../a.dart';
''');
    await analyzeTestPackageFiles();
    await resolveTestFile();
    // perform refactoring
    _createRefactoring('/home/test/000/1111/22/33/test.dart');
    await _assertSuccessfulRefactoring();
    assertFileChangeResult(pathA, '''
library lib;
part '22/33/test.dart';
''');
    assertFileChangeResult(testFile, '''
part of '../../a.dart';
''');
  }

  Future<void> test_renaming_part_that_uses_uri_in_part_of_2() async {
    // If the file is a part in a library, and the part-of directive uses a URI
    // rather than a library name, that will need updating too (if the relative
    // path to the parent changes).
    var pathA = convertPath('/home/test/000/1111/a.dart');
    testFile = convertPath('/home/test/000/1111/test.dart');
    addSource(pathA, '''
part of 'test.dart';
''');
    await resolveTestCode('''
part 'a.dart';
''');
    // perform refactoring
    _createRefactoring('/home/test/000/1111/22/test.dart');
    await _assertSuccessfulRefactoring();
    assertFileChangeResult(pathA, '''
part of '22/test.dart';
''');
    assertFileChangeResult(testFile, '''
part '../a.dart';
''');
  }

  Future<void> test_renaming_part_that_uses_uri_in_part_of_3() async {
    // If the file is a part in a library, and the part-of directive uses a URI
    // rather than a library name, that will need updating too (if the relative
    // path to the parent changes).
    var pathA = convertPath('/home/test/000/1111/a.dart');
    testFile = convertPath('/home/test/000/1111/test.dart');
    addSource(pathA, '''
part of 'test.dart';
''');
    await resolveTestCode('''
part 'a.dart';
''');
    // perform refactoring
    _createRefactoring('/home/test/000/1111/test2.dart');
    await _assertSuccessfulRefactoring();
    assertFileChangeResult(pathA, '''
part of 'test2.dart';
''');
    assertFileChangeResult(testFile, '''
part 'a.dart';
''');
  }

  Future<void> test_renaming_part_that_uses_uri_in_part_of_4() async {
    // If the file is a part in a library, and the part-of directive uses a URI
    // rather than a library name, that will need updating too (if the relative
    // path to the parent changes).
    var pathA = convertPath('/home/test/000/1111/a.dart');
    testFile = convertPath('/home/test/000/1111/test.dart');
    addSource(pathA, '''
part 'test.dart';
''');
    addTestSource('''
part of 'a.dart';
''');
    await analyzeTestPackageFiles();
    await resolveTestFile();
    // perform refactoring
    _createRefactoring('/home/test/000/1111/22/test.dart');
    await _assertSuccessfulRefactoring();
    assertFileChangeResult(pathA, '''
part '22/test.dart';
''');
    assertFileChangeResult(testFile, '''
part of '../a.dart';
''');
  }

  Future<void> test_renaming_part_that_uses_uri_in_part_of_5() async {
    // If the file is a part in a library, and the part-of directive uses a URI
    // rather than a library name, that will need updating too (if the relative
    // path to the parent changes).
    var pathA = convertPath('/home/test/000/1111/a.dart');
    testFile = convertPath('/home/test/000/1111/test.dart');
    addSource(pathA, '''
part 'test.dart';
''');
    addTestSource('''
part of 'a.dart';
''');
    await analyzeTestPackageFiles();
    await resolveTestFile();
    // perform refactoring
    _createRefactoring('/home/test/000/1111/test2.dart');
    await _assertSuccessfulRefactoring();
    assertFileChangeResult(pathA, '''
part 'test2.dart';
''');
    assertFileChangeResult(testFile, '''
part of 'a.dart';
''');
  }

  Future _assertFailedRefactoring(RefactoringProblemSeverity expectedSeverity,
      {String expectedMessage}) async {
    var status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, expectedSeverity,
        expectedMessage: expectedMessage);
  }

  /// Checks that all conditions are OK.
  Future _assertSuccessfulRefactoring() async {
    await assertRefactoringConditionsOK();
    refactoringChange = await refactoring.createChange();
  }

  void _createRefactoring(String newFile, {String oldFile}) {
    var refactoringWorkspace =
        RefactoringWorkspace([driverFor(testFile)], searchEngine);
    // Allow passing an oldName for when we don't want to rename testSource,
    // but otherwise fall back to testSource.fullname
    oldFile = convertPath(oldFile ?? testFile);
    refactoring = MoveFileRefactoring(
        resourceProvider, refactoringWorkspace, testAnalysisResult, oldFile);
    refactoring.newFile = convertPath(newFile);
  }
}
