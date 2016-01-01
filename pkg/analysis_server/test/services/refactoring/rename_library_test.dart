// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring.rename_library;

import 'package:analysis_server/plugin/protocol/protocol.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:unittest/unittest.dart';

import '../../utils.dart';
import 'abstract_rename.dart';

main() {
  initializeTestEnvironment();
  defineReflectiveTests(RenameLibraryTest);
}

@reflectiveTest
class RenameLibraryTest extends RenameRefactoringTest {
  void test_checkNewName() {
    indexTestUnit('''
library my.app;
''');
    _createRenameRefactoring();
    // null
    refactoring.newName = null;
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: "Library name must not be null.");
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: "Library name must not be blank.");
    // same name
    refactoring.newName = 'my.app';
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage:
            "The new name must be different than the current name.");
  }

  test_createChange() async {
    Source unitSource = addSource(
        '/part.dart',
        '''
part of my.app;
''');
    indexTestUnit('''
library my.app;
part 'part.dart';
''');
    index.index(
        context, context.resolveCompilationUnit2(unitSource, testSource));
    // configure refactoring
    _createRenameRefactoring();
    expect(refactoring.refactoringName, 'Rename Library');
    expect(refactoring.elementKindName, 'library');
    refactoring.newName = 'the.new.name';
    // validate change
    await assertSuccessfulRefactoring('''
library the.new.name;
part 'part.dart';
''');
    assertFileChangeResult(
        '/part.dart',
        '''
part of the.new.name;
''');
  }

  test_createChange_hasWhitespaces() async {
    Source unitSource = addSource(
        '/part.dart',
        '''
part of my .  app;
''');
    indexTestUnit('''
library my    . app;
part 'part.dart';
''');
    index.index(
        context, context.resolveCompilationUnit2(unitSource, testSource));
    // configure refactoring
    _createRenameRefactoring();
    expect(refactoring.refactoringName, 'Rename Library');
    expect(refactoring.elementKindName, 'library');
    refactoring.newName = 'the.new.name';
    // validate change
    await assertSuccessfulRefactoring('''
library the.new.name;
part 'part.dart';
''');
    assertFileChangeResult(
        '/part.dart',
        '''
part of the.new.name;
''');
  }

  void _createRenameRefactoring() {
    createRenameRefactoringForElement(testUnitElement.library);
  }
}
