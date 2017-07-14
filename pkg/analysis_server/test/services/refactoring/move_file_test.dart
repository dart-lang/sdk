// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
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

  @failingTest
  test_file_definingUnit() async {
    fail('The move file refactoring is not supported under the new driver');
    String pathA = '/project/000/1111/a.dart';
    String pathB = '/project/000/1111/b.dart';
    String pathC = '/project/000/1111/22/c.dart';
    String pathD = '/project/000/1111/333/d.dart';
    testFile = '/project/000/1111/test.dart';
    addSource('/absolute/uri.dart', '');
    addSource(pathA, 'part of lib;');
    addSource(pathB, "import 'test.dart';");
    addSource(pathC, '');
    addSource(pathD, '');
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
  test_file_importedLibrary() async {
    fail('The move file refactoring is not supported under the new driver');
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
    fail('The move file refactoring is not supported under the new driver');
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
    fail('The move file refactoring is not supported under the new driver');
    // configure packages
    testFile = '/packages/my_pkg/lib/aaa/test.dart';
    provider.newFile(testFile, '');
    // TODO(brianwilkerson) Figure out what this should be replaced with.
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
    fail('The move file refactoring is not supported under the new driver');
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
  test_file_sourcedUnit() async {
    fail('The move file refactoring is not supported under the new driver');
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
  test_file_sourcedUnit_multipleLibraries() async {
    fail('The move file refactoring is not supported under the new driver');
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
  test_project() async {
    fail('The move file refactoring is not supported under the new driver');
    String pubspecPath = '/testName/pubspec.yaml';
    String appPath = '/testName/bin/myApp.dart';
    provider.newFile(pubspecPath, '''
name: testName
version: 0.0.1
description: My pubspec file.
''');
    addSource('/testName/lib/myLib.dart', '');
    addSource(appPath, '''
import 'package:testName/myLib.dart';
export 'package:testName/myLib.dart';
''');
    // configure Uri resolves
    // TODO(brianwilkerson) Figure out what this should be replaced with.
//    context.sourceFactory = new SourceFactory([
//      new DartUriResolver(sdk),
//      new PackageMapUriResolver(provider, <String, List<Folder>>{
//        'testName': <Folder>[provider.getResource('/testName/lib')]
//      }),
//      resourceResolver,
//    ]);
    // perform refactoring
    refactoring = new MoveFileRefactoring(
        provider, searchEngine, null, null, '/testName');
    refactoring.newFile = '/newName';
    await _assertSuccessfulRefactoring();
    assertFileChangeResult(pubspecPath, '''
name: newName
version: 0.0.1
description: My pubspec file.
''');
    assertFileChangeResult(appPath, '''
import 'package:newName/myLib.dart';
export 'package:newName/myLib.dart';
''');
  }

  /**
   * Checks that all conditions are OK.
   */
  Future _assertSuccessfulRefactoring() async {
    await assertRefactoringConditionsOK();
    refactoringChange = await refactoring.createChange();
  }

  void _createRefactoring(String newName) {
    refactoring =
        new MoveFileRefactoring(provider, searchEngine, null, testSource, null);
    refactoring.newFile = newName;
  }
}
