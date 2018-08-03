// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

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
part '/absolute/uri.dart';
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
part '/absolute/uri.dart';
''');
  }

  @failingTest
  test_file_importedLibrary_sideways() async {
    fail('Not yet implemented/tested');
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

  @failingTest
  test_file_importedLibrary_down() async {
    fail('Not yet implemented/tested');
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

  @failingTest
  test_file_importedLibrary_package() async {
    fail('Not yet implemented/tested');
    // configure packages
    testFile = '/packages/my_pkg/lib/aaa/test.dart';
    newFile(testFile, content: '');
    // TODO(brianwilkerson) Figure out what this should be replaced with.
    // TODO(dantup): Change this to use addPackageSource
//    Map<String, List<Folder>> packageMap = {
//      'my_pkg': <Folder>[provider.getResource('/packages/my_pkg/lib')]
//    };
//    context.sourceFactory = new SourceFactory([
//      new DartUriResolver(sdk),
//      new PackageMapUriResolver(provider, packageMap),
//      resourceResolver
//    ]);
    // do testing
    String pathA = '/project/bin/a.dart';
    addSource(pathA, '''
import 'package:my_pkg/aaa/test.dart';
''');
    addTestSource('', Uri.parse('package:my_pkg/aaa/test.dart'));
    // perform refactoring
    _createRefactoring('/packages/my_pkg/lib/bbb/ccc/new_name.dart');
    await _assertSuccessfulRefactoring();
    assertFileChangeResult(pathA, '''
import 'package:my_pkg/bbb/ccc/new_name.dart';
''');
    assertNoFileChange(testFile);
  }

  @failingTest
  test_file_importedLibrary_up() async {
    fail('Not yet implemented/tested');
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
  test_file_referenced_by_multiple_libraries() async {
    fail('Not yet implemented/tested');
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

  @failingTest
  test_renaming_part_that_uses_uri_in_part_of() async {
    // If the file is a part in a library, and the part-of directive uses a URI
    // rather than a library name, that will need updating too (if the relative
    // path to the parent changes).
    fail('Not yet implemented/tested');
  }

  @failingTest
  test_projectFolder() async {
    fail('Not yet implemented/tested');
  }

  @failingTest
  test_folder_inside_project() async {
    fail('Not yet implemented/tested');
  }

  @failingTest
  test_folder_outside_workspace_returns_failure() async {
    fail('Not yet implemented/tested');
  }

  @failingTest
  test_project_folder_ancestor() async {
    fail('Not yet implemented/tested');
  }

  @failingTest
  test_nonexistent_file_returns_suitable_failure() async {
    fail('Not yet implemented/tested');
  }

  @failingTest
  test_dart_uris_are_unmodified() async {
    // TODO(dantup): See _computeNewUri implementation which currently only
    // handles relative + package: urls (package url handling is also incomplete)
    fail('Not yet implemented/tested');
  }

  /**
   * Checks that all conditions are OK.
   */
  Future _assertSuccessfulRefactoring() async {
    await assertRefactoringConditionsOK();
    refactoringChange = await refactoring.createChange();
  }

  void _createRefactoring(String newName) {
    var workspace = new RefactoringWorkspace([driver], searchEngine);
    refactoring =
        new MoveFileRefactoring(resourceProvider, workspace, testSource, null);
    refactoring.newFile = newName;
  }
}
