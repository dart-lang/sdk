// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring.move_files;

import 'dart:async';

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'abstract_refactoring.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(MoveFileTest);
}


@ReflectiveTestCase()
class MoveFileTest extends RefactoringTest {
  MoveFileRefactoring refactoring;

  test_definingUnit() {
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
import '22/c.dart';
export '333/d.dart';
part 'a.dart';
part '/absolute/uri.dart';
''');
    _performAnalysis();
    // perform refactoring
    _createRefactoring('/project/000/1111/22/new_name.dart');
    return _assertSuccessfulRefactoring().then((_) {
      assertNoFileChange(pathA);
      assertFileChangeResult(pathB, "import '22/new_name.dart';");
      assertNoFileChange(pathC);
      assertFileChangeResult(testFile, '''
library lib;
import 'c.dart';
export '../333/d.dart';
part '../a.dart';
part '/absolute/uri.dart';
''');
    });
  }

  test_importedLibrary() {
    String pathA = '/project/000/1111/a.dart';
    testFile = '/project/000/1111/sub/folder/test.dart';
    addSource(pathA, '''
import 'sub/folder/test.dart';
''');
    addTestSource('');
    _performAnalysis();
    // perform refactoring
    _createRefactoring('/project/000/new/folder/name/new_name.dart');
    return _assertSuccessfulRefactoring().then((_) {
      assertFileChangeResult(pathA, '''
import '../new/folder/name/new_name.dart';
''');
      assertNoFileChange(testFile);
    });
  }

  test_importedLibrary_down() {
    String pathA = '/project/000/1111/a.dart';
    testFile = '/project/000/1111/test.dart';
    addSource(pathA, '''
import 'test.dart';
''');
    addTestSource('');
    _performAnalysis();
    // perform refactoring
    _createRefactoring('/project/000/1111/22/new_name.dart');
    return _assertSuccessfulRefactoring().then((_) {
      assertFileChangeResult(pathA, '''
import '22/new_name.dart';
''');
      assertNoFileChange(testFile);
    });
  }

  test_importedLibrary_up() {
    String pathA = '/project/000/1111/a.dart';
    testFile = '/project/000/1111/22/test.dart';
    addSource(pathA, '''
import '22/test.dart';
''');
    addTestSource('');
    _performAnalysis();
    // perform refactoring
    _createRefactoring('/project/000/1111/new_name.dart');
    return _assertSuccessfulRefactoring().then((_) {
      assertFileChangeResult(pathA, '''
import 'new_name.dart';
''');
      assertNoFileChange(testFile);
    });
  }

  test_sourcedUnit() {
    String pathA = '/project/000/1111/a.dart';
    testFile = '/project/000/1111/22/test.dart';
    addSource(pathA, '''
part '22/test.dart';
''');
    addTestSource('');
    _performAnalysis();
    // perform refactoring
    _createRefactoring('/project/000/1111/22/new_name.dart');
    return _assertSuccessfulRefactoring().then((_) {
      assertFileChangeResult(pathA, '''
part '22/new_name.dart';
''');
      assertNoFileChange(testFile);
    });
  }

  test_sourcedUnit_multipleLibraries() {
    String pathA = '/project/000/1111/a.dart';
    String pathB = '/project/000/b.dart';
    testFile = '/project/000/1111/22/test.dart';
    addSource(pathA, '''
part '22/test.dart';
''');
    addSource(pathB, '''
part '1111/22/test.dart';
''');
    addTestSource('');
    _performAnalysis();
    // perform refactoring
    _createRefactoring('/project/000/1111/22/new_name.dart');
    return _assertSuccessfulRefactoring().then((_) {
      assertFileChangeResult(pathA, '''
part '22/new_name.dart';
''');
      assertFileChangeResult(pathB, '''
part '1111/22/new_name.dart';
''');
      assertNoFileChange(testFile);
    });
  }

  /**
   * Checks that all conditions are OK.
   */
  Future _assertSuccessfulRefactoring() {
    return assertRefactoringConditionsOK().then((_) {
      return refactoring.createChange().then((SourceChange refactoringChange) {
        this.refactoringChange = refactoringChange;
      });
    });
  }

  void _createRefactoring(String newName) {
    refactoring = new MoveFileRefactoring(searchEngine, context, testSource);
    refactoring.newFile = newName;
  }

  void _performAnalysis() {
    while (true) {
      AnalysisResult result = context.performAnalysisTask();
      if (!result.hasMoreWork) {
        break;
      }
      for (ChangeNotice notice in result.changeNotices) {
        if (notice.source.fullName.startsWith('/project/')) {
          index.indexUnit(context, notice.compilationUnit);
        }
      }
    }
  }
}
