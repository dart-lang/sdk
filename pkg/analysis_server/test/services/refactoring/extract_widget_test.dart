// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/extract_widget.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_refactoring.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtractWidgetTest);
  });
}

@reflectiveTest
class ExtractWidgetTest extends RefactoringTest {
  ExtractWidgetRefactoringImpl refactoring;

  test_checkAllConditions_selection() async {
    addFlutterPackage();
    await indexTestUnit('''
import 'package:flutter/material.dart';
class C {}
''');
    _createRefactoringForStringOffset('class C');

    RefactoringStatus status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL);
  }

  test_checkName() async {
    addFlutterPackage();
    await indexTestUnit('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Text('AAA');
  }
}
''');
    _createRefactoringForStringOffset('new Text');

    // null
    refactoring.name = null;
    assertRefactoringStatus(
        refactoring.checkName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: 'Class name must not be null.');

    // empty
    refactoring.name = '';
    assertRefactoringStatus(
        refactoring.checkName(), RefactoringProblemSeverity.FATAL,
        expectedMessage: 'Class name must not be empty.');

    // OK
    refactoring.name = 'Test';
    assertRefactoringStatusOK(refactoring.checkName());
  }

  test_expression() async {
    addFlutterPackage();
    await indexTestUnit('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Row(
      children: <Widget>[
        new Column(
          children: <Widget>[
            new Text('AAA'),
            new Text('BBB'),
          ],
        ),
        new Text('CCC'),
        new Text('DDD'),
      ],
    );
  }
}
''');
    _createRefactoringForStringOffset('new Column');

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Row(
      children: <Widget>[
        new Test(),
        new Text('CCC'),
        new Text('DDD'),
      ],
    );
  }
}

class Test extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Column(
      children: <Widget>[
        new Text('AAA'),
        new Text('BBB'),
      ],
    );
  }
}
''');
  }

  test_refactoringName() async {
    addFlutterPackage();
    await indexTestUnit('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Text('AAA');
  }
}
''');
    _createRefactoringForStringOffset('new Text');
    expect(refactoring.refactoringName, 'Extract Widget');
  }

  Future<void> _assertRefactoringChange(String expectedCode) async {
    SourceChange refactoringChange = await refactoring.createChange();
    this.refactoringChange = refactoringChange;
    assertTestChangeResult(expectedCode);
  }

  /**
   * Checks that all conditions are OK and the result of applying the change
   * to [testUnit] is [expectedCode].
   */
  Future<void> _assertSuccessfulRefactoring(String expectedCode) async {
    await assertRefactoringConditionsOK();
    await _assertRefactoringChange(expectedCode);
  }

  void _createRefactoring(int offset) {
    refactoring = new ExtractWidgetRefactoring(
        searchEngine, driver.currentSession, testUnit, offset);
    refactoring.name = 'Test';
  }

  /**
   * Creates a new refactoring in [refactoring] at the offset of the given
   * [search] pattern.
   */
  void _createRefactoringForStringOffset(String search) {
    int offset = findOffset(search);
    _createRefactoring(offset);
  }
}
