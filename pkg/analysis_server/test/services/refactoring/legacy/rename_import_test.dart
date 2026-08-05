// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/diagnostic/diagnostic.dart' as diag;
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_rename.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RenameImportTest);
  });
}

@reflectiveTest
class RenameImportTest extends RenameRefactoringTest {
  Future<void> test_checkNewName() async {
    await indexTestUnit("import 'dart:async' as test;");
    _createRefactoring("import 'dart:");
    expect(refactoring.oldName, 'test');
    // same
    refactoring.newName = 'test';
    assertRefactoringStatus(
      refactoring.checkNewName(),
      RefactoringProblemSeverity.FATAL,
      expectedMessage: 'The new name must be different than the current name.',
    );
    // empty
    refactoring.newName = '';
    assertRefactoringStatusOK(refactoring.checkNewName());
    // OK
    refactoring.newName = 'newName';
    assertRefactoringStatusOK(refactoring.checkNewName());
  }

  Future<void> test_checkNewName_sameName_empty() async {
    await indexTestUnit('''
import 'dart:math';
void f(Random r) {}
''');

    _createRefactoring("import 'dart:math");

    refactoring.newName = '';
    assertRefactoringStatus(
      refactoring.checkNewName(),
      RefactoringProblemSeverity.FATAL,
      expectedMessage: 'The new name must be different than the current name.',
    );
  }

  Future<void> test_createChange_add() async {
    await indexTestUnit('''
import 'dart:async';
// ignore: multiple_combinators
import 'dart:math' show Random, min hide max;
void f() {
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
// ignore: multiple_combinators
import 'dart:math' as newName show Random, min hide max;
void f() {
  Future f;
  newName.Random r;
  newName.min(1, 2);
}
''');
  }

  Future<void> test_createChange_add_configuration() async {
    await indexTestUnit('''
import 'dart:async'
    if (dart.library.io) 'dart:async';
FutureOr<void> a;
''');
    // configure refactoring
    _createRefactoring("import 'dart:async'");
    expect(refactoring.refactoringName, 'Rename Import Prefix');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
import 'dart:async' as newName
    if (dart.library.io) 'dart:async';
newName.FutureOr<void> a;
''');
  }

  Future<void> test_createChange_add_deferred() async {
    await indexTestUnit(
      '''
import 'dart:async' deferred;
x() => Completer<void>();
''',
      ignore: [diag.missingPrefixInDeferredImport],
    );
    // configure refactoring
    _createRefactoring("import 'dart:async'");
    expect(refactoring.refactoringName, 'Rename Import Prefix');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
import 'dart:async' deferred as newName;
x() => newName.Completer<void>();
''');
  }

  Future<void> test_createChange_add_hide() async {
    await indexTestUnit('''
import 'dart:async' hide Completer;
FutureOr<void> a;
''');
    // configure refactoring
    _createRefactoring("import 'dart:async'");
    expect(refactoring.refactoringName, 'Rename Import Prefix');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
import 'dart:async' as newName hide Completer;
newName.FutureOr<void> a;
''');
  }

  Future<void>
  test_createChange_add_interpolationExpression_hasCurlyBrackets() async {
    await indexTestUnit(r'''
import 'dart:async';
void f() {
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
void f() {
  newName.Future f;
  print('Future type: ${newName.Future}');
}
''');
  }

  Future<void>
  test_createChange_add_interpolationExpression_noCurlyBrackets() async {
    await indexTestUnit(r'''
import 'dart:async';
void f() {
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
void f() {
  newName.Future f;
  print('Future type: ${newName.Future}');
}
''');
  }

  Future<void> test_createChange_add_show() async {
    await indexTestUnit('''
import 'dart:async' show FutureOr;
FutureOr<void> a;
''');
    // configure refactoring
    _createRefactoring("import 'dart:async'");
    expect(refactoring.refactoringName, 'Rename Import Prefix');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
import 'dart:async' as newName show FutureOr;
newName.FutureOr<void> a;
''');
  }

  Future<void> test_createChange_change_className() async {
    await indexTestUnit('''
import 'dart:math' as test;
import 'dart:async' as test;
void f() {
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
void f() {
  newName.Future f;
}
''');
  }

  Future<void> test_createChange_change_deferred() async {
    await indexTestUnit('''
import 'dart:async' deferred as oldName;
x() => oldName.Completer<void>();
''');
    // configure refactoring
    _createRefactoring("import 'dart:async'");
    expect(refactoring.refactoringName, 'Rename Import Prefix');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
import 'dart:async' deferred as newName;
x() => newName.Completer<void>();
''');
  }

  Future<void> test_createChange_change_function() async {
    await indexTestUnit('''
import 'dart:math' as test;
import 'dart:async' as test;
void f() {
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
void f() {
  newName.max(1, 2);
  test.Future f;
}
''');
  }

  Future<void> test_createChange_change_hide() async {
    await indexTestUnit('''
import 'dart:async' as oldName hide Completer;
oldName.FutureOr<void> a;
''');
    // configure refactoring
    _createRefactoring("import 'dart:async'");
    expect(refactoring.refactoringName, 'Rename Import Prefix');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
import 'dart:async' as newName hide Completer;
newName.FutureOr<void> a;
''');
  }

  Future<void> test_createChange_change_onPrefixElement() async {
    await indexTestUnit('''
import 'dart:async' as test;
import 'dart:math' as test;
void f() {
  test.Future f;
  test.pi;
  test.e;
}
''');
    // configure refactoring
    createRenameRefactoringAtString('test.pi');
    expect(refactoring.refactoringName, 'Rename Import Prefix');
    expect(refactoring.oldName, 'test');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
import 'dart:async' as test;
import 'dart:math' as newName;
void f() {
  test.Future f;
  newName.pi;
  newName.e;
}
''');
  }

  Future<void> test_createChange_change_show() async {
    await indexTestUnit('''
import 'dart:async' as oldName show FutureOr;
oldName.FutureOr<void> a;
''');
    // configure refactoring
    _createRefactoring("import 'dart:async'");
    expect(refactoring.refactoringName, 'Rename Import Prefix');
    refactoring.newName = 'newName';
    // validate change
    return assertSuccessfulRefactoring('''
import 'dart:async' as newName show FutureOr;
newName.FutureOr<void> a;
''');
  }

  Future<void> test_createChange_remove() async {
    await indexTestUnit('''
import 'dart:math' as test;
import 'dart:async' as test;
void f() {
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
void f() {
  Future f;
}
''');
  }

  Future<void> test_createChange_remove_deferred_disallowed() async {
    await indexTestUnit('''
import 'dart:async' deferred as oldName;
x() => oldName.Completer<void>();
''');
    // configure refactoring
    _createRefactoring("import 'dart:async'");
    expect(refactoring.refactoringName, 'Rename Import Prefix');
    refactoring.newName = '';
    // validate change
    assertRefactoringStatus(
      await refactoring.checkFinalConditions(),
      RefactoringProblemSeverity.ERROR,
      expectedMessage: 'Deferred imports require a prefix',
    );
  }

  Future<void> test_createChange_remove_hide() async {
    await indexTestUnit('''
import 'dart:async' as oldName hide Completer;
oldName.FutureOr<void> a;
''');
    // configure refactoring
    _createRefactoring("import 'dart:async'");
    expect(refactoring.refactoringName, 'Rename Import Prefix');
    refactoring.newName = '';
    // validate change
    return assertSuccessfulRefactoring('''
import 'dart:async' hide Completer;
FutureOr<void> a;
''');
  }

  Future<void> test_createChange_remove_show() async {
    await indexTestUnit('''
import 'dart:async' as oldName show FutureOr;
oldName.FutureOr<void> a;
''');
    // configure refactoring
    _createRefactoring("import 'dart:async'");
    expect(refactoring.refactoringName, 'Rename Import Prefix');
    refactoring.newName = '';
    // validate change
    return assertSuccessfulRefactoring('''
import 'dart:async' show FutureOr;
FutureOr<void> a;
''');
  }

  Future<void> test_oldName_empty() async {
    await indexTestUnit('''
import 'dart:math';
import 'dart:async';
void f() {
  Future f;
}
''');
    // configure refactoring
    _createRefactoring("import 'dart:async");
    expect(refactoring.refactoringName, 'Rename Import Prefix');
    expect(refactoring.oldName, '');
  }

  void _createRefactoring(String search) {
    var directive = findNode.import(search);
    createRenameRefactoringForElement2(
      MockLibraryImportElement(directive.libraryImport!),
    );
  }
}
