// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring.rename_label;

import 'package:analysis_server/src/protocol.dart';
import 'package:unittest/unittest.dart';

import '../../reflective_tests.dart';
import 'abstract_rename.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(RenameLabelTest);
}


@ReflectiveTestCase()
class RenameLabelTest extends RenameRefactoringTest {
  test_checkNewName_LocalVariableElement() {
    indexTestUnit('''
main() {
test:
  while (true) {
    break test;
  }
}
''');
    createRenameRefactoringAtString('test:');
    // null
    refactoring.newName = null;
    assertRefactoringStatus(
        refactoring.checkNewName(),
        RefactoringProblemSeverity.FATAL,
        expectedMessage: "Label name must not be null.");
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
        refactoring.checkNewName(),
        RefactoringProblemSeverity.FATAL,
        expectedMessage: "Label name must not be empty.");
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  test_createChange() {
    indexTestUnit('''
main() {
test:
  while (true) {
    break test;
  }
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test:');
    expect(refactoring.refactoringName, 'Rename Label');
    expect(refactoring.elementKindName, 'label');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
main() {
newName:
  while (true) {
    break newName;
  }
}
''');
  }

  test_oldName() {
    indexTestUnit('''
main() {
test:
  while (true) {
    break test;
  }
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test:');
    // old name
    expect(refactoring.oldName, 'test');
  }
}
