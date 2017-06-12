// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_rename.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RenameImportTest);
  });
}

@reflectiveTest
class RenameImportTest extends RenameRefactoringTest {
  test_checkNewName() async {
    await indexTestUnit("import 'dart:async' as test;");
    _createRefactoring("import 'dart:");
    expect(refactoring.oldName, 'test');
    // null
    refactoring.newName = null;
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: "Import prefix name must not be null.");
    // same
    refactoring.newName = 'test';
    assertRefactoringStatus(
        refactoring.checkNewName(), RefactoringProblemSeverity.FATAL,
        expectedMessage:
            "The new name must be different than the current name.");
    // empty
    refactoring.newName = '';
    assertRefactoringStatusOK(refactoring.checkNewName());
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  test_createChange_add() async {
    await indexTestUnit('''
import 'dart:async';
import 'dart:math' show Random, min hide max;
main() {
  Future f;
  Random r;
  min(1, 2);
}
''');
    // configure refactoring
    _createRefactoring("import 'dart:math");
    expect(refactoring.refactoringName, 'Rename Import Prefix');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
import 'dart:async';
import 'dart:math' as newName show Random, min hide max;
main() {
  Future f;
  newName.Random r;
  newName.min(1, 2);
}
''');
  }

  test_createChange_add_interpolationExpression_hasCurlyBrackets() async {
    await indexTestUnit(r'''
import 'dart:async';
main() {
  Future f;
  print('Future type: ${Future}');
}
''');
    // configure refactoring
    _createRefactoring("import 'dart:async");
    expect(refactoring.refactoringName, 'Rename Import Prefix');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring(r'''
import 'dart:async' as newName;
main() {
  newName.Future f;
  print('Future type: ${newName.Future}');
}
''');
  }

  test_createChange_add_interpolationExpression_noCurlyBrackets() async {
    await indexTestUnit(r'''
import 'dart:async';
main() {
  Future f;
  print('Future type: $Future');
}
''');
    // configure refactoring
    _createRefactoring("import 'dart:async");
    expect(refactoring.refactoringName, 'Rename Import Prefix');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring(r'''
import 'dart:async' as newName;
main() {
  newName.Future f;
  print('Future type: ${newName.Future}');
}
''');
  }

  test_createChange_change_className() async {
    await indexTestUnit('''
import 'dart:math' as test;
import 'dart:async' as test;
main() {
  test.Future f;
}
''');
    // configure refactoring
    _createRefactoring("import 'dart:async");
    expect(refactoring.refactoringName, 'Rename Import Prefix');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
import 'dart:math' as test;
import 'dart:async' as newName;
main() {
  newName.Future f;
}
''');
  }

  test_createChange_change_function() async {
    await indexTestUnit('''
import 'dart:math' as test;
import 'dart:async' as test;
main() {
  test.max(1, 2);
  test.Future f;
}
''');
    // configure refactoring
    _createRefactoring("import 'dart:math");
    expect(refactoring.refactoringName, 'Rename Import Prefix');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
import 'dart:math' as newName;
import 'dart:async' as test;
main() {
  newName.max(1, 2);
  test.Future f;
}
''');
  }

  test_createChange_change_onPrefixElement() async {
    await indexTestUnit('''
import 'dart:async' as test;
import 'dart:math' as test;
main() {
  test.Future f;
  test.PI;
  test.E;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test.PI');
    expect(refactoring.refactoringName, 'Rename Import Prefix');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
import 'dart:async' as test;
import 'dart:math' as newName;
main() {
  test.Future f;
  newName.PI;
  newName.E;
}
''');
  }

  test_createChange_remove() async {
    await indexTestUnit('''
import 'dart:math' as test;
import 'dart:async' as test;
main() {
  test.Future f;
}
''');
    // configure refactoring
    _createRefactoring("import 'dart:async");
    expect(refactoring.refactoringName, 'Rename Import Prefix');
    expect(refactoring.oldName, 'test');
    refactoring.newName = '';
    // validate change
    return assertSuccessfulRefactoring('''
import 'dart:math' as test;
import 'dart:async';
main() {
  Future f;
}
''');
  }

  test_oldName_empty() async {
    await indexTestUnit('''
import 'dart:math';
import 'dart:async';
main() {
  Future f;
}
''');
    // configure refactoring
    _createRefactoring("import 'dart:async");
    expect(refactoring.refactoringName, 'Rename Import Prefix');
    expect(refactoring.oldName, '');
  }

  void _createRefactoring(String search) {
    ImportDirective directive =
        findNodeAtString(search, (node) => node is ImportDirective);
    createRenameRefactoringForElement(directive.element);
  }
}
