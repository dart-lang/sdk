// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_rename.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RenameLabelTest);
  });
}

@reflectiveTest
class RenameLabelTest extends RenameRefactoringTest {
  test_checkNewName_LocalVariableElement() async {
    await indexTestUnit('''
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
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: "Label name must not be null.");
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: "Label name must not be empty.");
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  test_createChange() async {
    await indexTestUnit('''
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

  test_oldName() async {
    await indexTestUnit('''
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
