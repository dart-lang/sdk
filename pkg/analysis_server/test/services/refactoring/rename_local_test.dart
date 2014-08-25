// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.services.refactoring.rename_local;

import 'package:analysis_server/src/protocol.dart';
import 'package:analysis_testing/reflective_tests.dart';
import 'package:unittest/unittest.dart';

import 'abstract_rename.dart';


main() {
  groupSep = ' | ';
  runReflectiveTests(RenameLocalTest);
}


@ReflectiveTestCase()
class RenameLocalTest extends RenameRefactoringTest {
  test_checkFinalConditions_hasLocalFunction_after() {
    indexTestUnit('''
main() {
  int test = 0;
  newName() => 1;
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    return refactoring.checkFinalConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.ERROR,
          expectedMessage: "Duplicate function 'newName'.",
          expectedContextSearch: 'newName() => 1');
    });
  }

  test_checkFinalConditions_hasLocalFunction_before() {
    indexTestUnit('''
main() {
  newName() => 1;
  int test = 0;
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    return refactoring.checkFinalConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.ERROR,
          expectedMessage: "Duplicate function 'newName'.");
    });
  }

  test_checkFinalConditions_hasLocalVariable_after() {
    indexTestUnit('''
main() {
  int test = 0;
  var newName = 1;
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    return refactoring.checkFinalConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.ERROR,
          expectedMessage: "Duplicate local variable 'newName'.",
          expectedContextSearch: 'newName = 1;');
    });
  }

  test_checkFinalConditions_hasLocalVariable_before() {
    indexTestUnit('''
main() {
  var newName = 1;
  int test = 0;
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    return refactoring.checkFinalConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.ERROR,
          expectedMessage: "Duplicate local variable 'newName'.",
          expectedContextSearch: 'newName = 1;');
    });
  }

  test_checkFinalConditions_hasLocalVariable_otherBlock() {
    indexTestUnit('''
main() {
  {
    var newName = 1;
  }
  {
    int test = 0;
  }
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringConditionsOK();
  }

  test_checkFinalConditions_hasLocalVariable_otherFunction() {
    indexTestUnit('''
main() {
  int test = 0;
}
main2() {
  var newName = 1;
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringConditionsOK();
  }

  test_checkFinalConditions_shadows_classMember() {
    indexTestUnit('''
class A {
  var newName = 1;
  main() {
    var test = 0;
    print(newName);
  }
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    return refactoring.checkFinalConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.ERROR,
          expectedMessage: 'Usage of field "A.newName" declared in "test.dart" '
              'will be shadowed by renamed local variable.',
          expectedContextSearch: 'newName);');
    });
  }

  test_checkFinalConditions_shadows_classMemberOK_qualifiedReference() {
    indexTestUnit('''
class A {
  var newName = 1;
  main() {
    var test = 0;
    print(this.newName);
  }
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    return assertRefactoringConditionsOK();
  }

  test_checkFinalConditions_shadows_topLevelFunction() {
    indexTestUnit('''
newName() {}
main() {
  var test = 0;
  newName(); // ref
}
''');
    createRenameRefactoringAtString('test = 0');
    // check status
    refactoring.newName = 'newName';
    return refactoring.checkFinalConditions().then((status) {
      assertRefactoringStatus(
          status,
          RefactoringProblemSeverity.ERROR,
          expectedContextSearch: 'newName(); // ref');
    });
  }

  test_checkNewName_FunctionElement() {
    indexTestUnit('''
main() {
  int test() {}
}
''');
    createRenameRefactoringAtString('test() {}');
    // null
    refactoring.newName = null;
    assertRefactoringStatus(
        refactoring.checkNewName(),
        RefactoringProblemSeverity.FATAL,
        expectedMessage: "Function name must not be null.");
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  test_checkNewName_LocalVariableElement() {
    indexTestUnit('''
main() {
  int test = 0;
}
''');
    createRenameRefactoringAtString('test = 0;');
    // null
    refactoring.newName = null;
    assertRefactoringStatus(
        refactoring.checkNewName(),
        RefactoringProblemSeverity.FATAL,
        expectedMessage: "Variable name must not be null.");
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
        refactoring.checkNewName(),
        RefactoringProblemSeverity.FATAL,
        expectedMessage: "Variable name must not be empty.");
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  test_checkNewName_LocalVariableElement_const() {
    indexTestUnit('''
main() {
  const int TEST = 0;
}
''');
    createRenameRefactoringAtString('TEST = 0;');
    // null
    refactoring.newName = null;
    assertRefactoringStatus(
        refactoring.checkNewName(),
        RefactoringProblemSeverity.FATAL,
        expectedMessage: "Constant name must not be null.");
    // empty
    refactoring.newName = '';
    assertRefactoringStatus(
        refactoring.checkNewName(),
        RefactoringProblemSeverity.FATAL,
        expectedMessage: "Constant name must not be empty.");
    // same
    refactoring.newName = 'TEST';
    assertRefactoringStatus(
        refactoring.checkNewName(),
        RefactoringProblemSeverity.FATAL,
        expectedMessage: "The new name must be different than the current name.");
    // OK
    refactoring.newName = 'NEW_NAME';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  test_checkNewName_ParameterElement() {
    indexTestUnit('''
main(test) {
}
''');
    createRenameRefactoringAtString('test) {');
    // null
    refactoring.newName = null;
    assertRefactoringStatus(
        refactoring.checkNewName(),
        RefactoringProblemSeverity.FATAL,
        expectedMessage: "Parameter name must not be null.");
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  test_createChange_localFunction() {
    indexTestUnit('''
main() {
  int test() => 0;
  print(test);
  print(test());
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test() => 0');
    expect(refactoring.refactoringName, 'Rename Local Function');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRename('''
main() {
  int newName() => 0;
  print(newName);
  print(newName());
}
''');
  }

  test_createChange_localFunction_sameNameDifferenceScopes() {
    indexTestUnit('''
main() {
  {
    int test() => 0;
    print(test);
  }
  {
    int test() => 1;
    print(test);
  }
  {
    int test() => 2;
    print(test);
  }
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test() => 1');
    expect(refactoring.refactoringName, 'Rename Local Function');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRename('''
main() {
  {
    int test() => 0;
    print(test);
  }
  {
    int newName() => 1;
    print(newName);
  }
  {
    int test() => 2;
    print(test);
  }
}
''');
  }

  test_createChange_localVariable() {
    indexTestUnit('''
main() {
  int test = 0;
  test = 1;
  test += 2;
  print(test);
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test = 0');
    expect(refactoring.refactoringName, 'Rename Local Variable');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRename('''
main() {
  int newName = 0;
  newName = 1;
  newName += 2;
  print(newName);
}
''');
  }

  test_createChange_localVariable_sameNameDifferenceScopes() {
    indexTestUnit('''
main() {
  {
    int test = 0;
    print(test);
  }
  {
    int test = 1;
    print(test);
  }
  {
    int test = 2;
    print(test);
  }
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test = 1');
    expect(refactoring.refactoringName, 'Rename Local Variable');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRename('''
main() {
  {
    int test = 0;
    print(test);
  }
  {
    int newName = 1;
    print(newName);
  }
  {
    int test = 2;
    print(test);
  }
}
''');
  }

  test_createChange_parameter() {
    indexTestUnit('''
myFunction({int test}) {
  test = 1;
  test += 2;
  print(test);
}
main() {
  myFunction(test: 2);
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test}) {');
    expect(refactoring.refactoringName, 'Rename Parameter');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRename('''
myFunction({int newName}) {
  newName = 1;
  newName += 2;
  print(newName);
}
main() {
  myFunction(newName: 2);
}
''');
  }

  test_createChange_parameter_namedInOtherFile() {
    indexTestUnit('''
class A {
  A({test});
}
''');
    indexUnit('/test2.dart', '''
import 'test.dart';
main() {
  new A(test: 2);
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test});');
    expect(refactoring.refactoringName, 'Rename Parameter');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRename('''
class A {
  A({newName});
}
''').then((_) {
      assertFileChangeResult('/test2.dart', '''
import 'test.dart';
main() {
  new A(newName: 2);
}
''');
    });
  }

  test_oldName() {
    indexTestUnit('''
main() {
  int test = 0;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test = 0');
    // old name
    expect(refactoring.oldName, 'test');
  }
}
