// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_rename.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RenameLibraryTest);
  });
}

@reflectiveTest
class RenameLibraryTest extends RenameRefactoringTest {
  Future<void> test_checkNewName() async {
    await indexTestUnit('''
// @dart = 3.4
library my.app;
''');
    _createRenameRefactoring();
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
      refactoring.checkNewName(),
      RefactoringProblemSeverity.FATAL,
      expectedMessage: 'Library name must not be blank.',
    );
    // same name
    refactoring.newName = 'my.app';
    assertRefactoringStatus(
      refactoring.checkNewName(),
      RefactoringProblemSeverity.FATAL,
      expectedMessage: 'The new name must be different than the current name.',
    );
  }

  Future<void> test_createChange() async {
    newFile('$testPackageLibPath/part.dart', '''
// @dart = 3.4
part of my.app;
''');
    await indexTestUnit('''
// @dart = 3.4
library my.app;
part 'part.dart';
''');
    // configure refactoring
    _createRenameRefactoring();
    expect(refactoring.refactoringName, 'Rename Library');
    expect(refactoring.elementKindName, 'library');
    refactoring.newName = 'the.new.name';
    // validate change
    await assertSuccessfulRefactoring('''
// @dart = 3.4
library the.new.name;
part 'part.dart';
''');
    assertFileChangeResult('$testPackageLibPath/part.dart', '''
// @dart = 3.4
part of the.new.name;
''');
  }

  Future<void> test_createChange_hasWhitespaces() async {
    newFile('$testPackageLibPath/part.dart', '''
// @dart = 3.4
part of my .  app;
''');
    await indexTestUnit('''
// @dart = 3.4
library my    . app;
part 'part.dart';
''');
    // configure refactoring
    _createRenameRefactoring();
    expect(refactoring.refactoringName, 'Rename Library');
    expect(refactoring.elementKindName, 'library');
    refactoring.newName = 'the.new.name';
    // validate change
    await assertSuccessfulRefactoring('''
// @dart = 3.4
library the.new.name;
part 'part.dart';
''');
    assertFileChangeResult('$testPackageLibPath/part.dart', '''
// @dart = 3.4
part of the.new.name;
''');
  }

  void _createRenameRefactoring() {
    createRenameRefactoringForElement2(testLibraryElement2);
  }
}
