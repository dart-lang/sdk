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

  test_expression_localFunction() async {
    addFlutterPackage();
    await indexTestUnit('''
import 'package:flutter/material.dart';

Widget main() {
  Widget foo() {
    return new Row(
      children: <Widget>[
        new Text('AAA'),
        new Text('BBB'),
      ],
    );
  }
  return foo();
}
''');
    _createRefactoringForStringOffset('new Text');

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

Widget main() {
  Widget foo() {
    return new Row(
      children: <Widget>[
        new Test(),
        new Text('BBB'),
      ],
    );
  }
  return foo();
}

class Test extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Text('AAA');
  }
}
''');
  }

  test_expression_topFunction() async {
    addFlutterPackage();
    await indexTestUnit('''
import 'package:flutter/material.dart';

Widget main() {
  return new Row(
    children: <Widget>[
      new Text('AAA'),
      new Text('BBB'),
    ],
  );
}
''');
    _createRefactoringForStringOffset('new Text');

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

Widget main() {
  return new Row(
    children: <Widget>[
      new Test(),
      new Text('BBB'),
    ],
  );
}

class Test extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Text('AAA');
  }
}
''');
  }

  test_invocation_enclosingClass() async {
    addFlutterPackage();
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      child: new Text(''),
      onTap: () {
        foo();
      },
    );
  }

  void foo() {}
}
''');
    _createRefactoringForStringOffset('new GestureDetector');

    RefactoringStatus status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR);
  }

  test_invocation_otherClass() async {
    addFlutterPackage();
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class C {
  void foo() {}
}

class MyWidget extends StatelessWidget {
  C c = new C();

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      child: new Text(''),
      onTap: () {
        c.foo();
      },
    );
  }
}
''');
    _createRefactoringForStringOffset('new GestureDetector');

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

class C {
  void foo() {}
}

class MyWidget extends StatelessWidget {
  C c = new C();

  @override
  Widget build(BuildContext context) {
    return new Test(c);
  }
}

class Test extends StatelessWidget {
  final C c;

  Test(this.c);

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      child: new Text(''),
      onTap: () {
        c.foo();
      },
    );
  }
}
''');
  }

  test_parameters_field_read_enclosingClass() async {
    addFlutterPackage();
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  String field;

  @override
  Widget build(BuildContext context) {
    return new Text(field);
  }
}
''');
    _createRefactoringForStringOffset('new Text');

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  String field;

  @override
  Widget build(BuildContext context) {
    return new Test(field);
  }
}

class Test extends StatelessWidget {
  final String field;

  Test(this.field);

  @override
  Widget build(BuildContext context) {
    return new Text(field);
  }
}
''');
  }

  test_parameters_field_read_otherClass() async {
    addFlutterPackage();
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class C {
  String field;
}

class MyWidget extends StatelessWidget {
  C c = new C();

  @override
  Widget build(BuildContext context) {
    return new Text(c.field);
  }
}
''');
    _createRefactoringForStringOffset('new Text');

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

class C {
  String field;
}

class MyWidget extends StatelessWidget {
  C c = new C();

  @override
  Widget build(BuildContext context) {
    return new Test(c);
  }
}

class Test extends StatelessWidget {
  final C c;

  Test(this.c);

  @override
  Widget build(BuildContext context) {
    return new Text(c.field);
  }
}
''');
  }

  test_parameters_field_read_topLevelVariable() async {
    addFlutterPackage();
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

String field;

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Text(field);
  }
}
''');
    _createRefactoringForStringOffset('new Text');

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

String field;

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Test();
  }
}

class Test extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Text(field);
  }
}
''');
  }

  test_parameters_field_write_enclosingClass() async {
    addFlutterPackage();
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  String field;

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      child: new Text(''),
      onTap: () {
        field = '';
      },
    );
  }
}
''');
    _createRefactoringForStringOffset('new GestureDetector');

    RefactoringStatus status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR);
  }

  test_parameters_field_write_otherClass() async {
    addFlutterPackage();
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class C {
  String field;
}

class MyWidget extends StatelessWidget {
  C c = new C();

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      child: new Text(''),
      onTap: () {
        c.field = '';
      },
    );
  }
}
''');
    _createRefactoringForStringOffset('new GestureDetector');

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

class C {
  String field;
}

class MyWidget extends StatelessWidget {
  C c = new C();

  @override
  Widget build(BuildContext context) {
    return new Test(c);
  }
}

class Test extends StatelessWidget {
  final C c;

  Test(this.c);

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      child: new Text(''),
      onTap: () {
        c.field = '';
      },
    );
  }
}
''');
  }

  test_parameters_local_read_enclosingScope() async {
    addFlutterPackage();
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String local;
    return new Text(local);
  }
}
''');
    _createRefactoringForStringOffset('new Text');

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String local;
    return new Test(local);
  }
}

class Test extends StatelessWidget {
  final String local;

  Test(this.local);

  @override
  Widget build(BuildContext context) {
    return new Text(local);
  }
}
''');
  }

  test_parameters_local_write_enclosingScope() async {
    addFlutterPackage();
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String local;
    return new GestureDetector(
      child: new Text(''),
      onTap: () {
        local = '';
      },
    );
  }
}
''');
    _createRefactoringForStringOffset('new GestureDetector');

    RefactoringStatus status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR);
  }

  test_parameters_readField_readLocal() async {
    addFlutterPackage();
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  String field;

  @override
  Widget build(BuildContext context) {
    String local;
    return new Column(
      children: <Widget>[
        new Text(field),
        new Text(local),
      ],
    );
  }
}
''');
    _createRefactoringForStringOffset('new Column');

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  String field;

  @override
  Widget build(BuildContext context) {
    String local;
    return new Test(field, local);
  }
}

class Test extends StatelessWidget {
  final String field;
  final String local;

  Test(this.field, this.local);

  @override
  Widget build(BuildContext context) {
    return new Column(
      children: <Widget>[
        new Text(field),
        new Text(local),
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
