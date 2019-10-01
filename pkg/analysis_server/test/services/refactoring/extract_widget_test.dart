// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
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

  test_checkName_alreadyDeclared() async {
    addFlutterPackage();
    await indexTestUnit('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Container();
  }
}

class Test {}
''');
    _createRefactoringForStringOffset('new Container');

    refactoring.name = 'Test';
    assertRefactoringStatus(
        refactoring.checkName(), RefactoringProblemSeverity.ERROR,
        expectedMessage: "Library already declares class with name 'Test'.");
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
        Test(),
        new Text('CCC'),
        new Text('DDD'),
      ],
    );
  }
}

class Test extends StatelessWidget {
  const Test({
    Key key,
  }) : super(key: key);

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
        Test(),
        new Text('BBB'),
      ],
    );
  }
  return foo();
}

class Test extends StatelessWidget {
  const Test({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Text('AAA');
  }
}
''');
  }

  test_expression_onTypeName() async {
    addFlutterPackage();
    await indexTestUnit('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Container();
  }
}
''');
    _createRefactoringForStringOffset('tainer(');

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Test();
  }
}

class Test extends StatelessWidget {
  const Test({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Container();
  }
}
''');
  }

  test_expression_selection() async {
    addFlutterPackage();
    await indexTestUnit('''
import 'package:flutter/material.dart';

Widget main() {
  return new Container();
}
''');

    Future<void> assertResult(String str) async {
      int offset = findOffset(str);
      _createRefactoring(offset, str.length);

      await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

Widget main() {
  return Test();
}

class Test extends StatelessWidget {
  const Test({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return new Container();
  }
}
''');
    }

    await assertResult('Container');
    await assertResult('new Container');
    await assertResult('new Container(');
    await assertResult('new Container()');
    await assertResult('new Container();');
    await assertResult('taine');
    await assertResult('tainer');
    await assertResult('tainer(');
    await assertResult('tainer()');
    await assertResult('turn new Container');
    await assertResult('return new Container()');
    await assertResult('return new Container();');
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
      Test(),
      new Text('BBB'),
    ],
  );
}

class Test extends StatelessWidget {
  const Test({
    Key key,
  }) : super(key: key);

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

  test_invocation_enclosingSuperClass() async {
    addFlutterPackage();
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

abstract class MyInterface {
  void foo();
}

abstract class MyWidget extends StatelessWidget implements MyInterface {
  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      child: new Text(''),
      onTap: () {
        foo();
      },
    );
  }
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
    return Test(c: c);
  }
}

class Test extends StatelessWidget {
  const Test({
    Key key,
    @required this.c,
  }) : super(key: key);

  final C c;

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

  test_method() async {
    addFlutterPackage();
    await indexTestUnit('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return createColumn();
  }
  
  Widget createColumn() {
    var a = new Text('AAA');
    var b = new Text('BBB');
    return new Column(
      children: <Widget>[a, b],
    );
  }
}
''');
    _createRefactoringForStringOffset('createColumn() {');

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Test();
  }
}

class Test extends StatelessWidget {
  const Test({
    Key key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var a = new Text('AAA');
    var b = new Text('BBB');
    return new Column(
      children: <Widget>[a, b],
    );
  }
}
''');
  }

  test_method_parameters() async {
    addFlutterPackage();
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  String foo;

  @override
  Widget build(BuildContext context) {
    int bar = 1;
    return new Row(
      children: <Widget>[
        createColumn('aaa', bar),
        createColumn('bbb', 2),
      ],
    );
  }
  
  Widget createColumn(String p1, int p2) {
    var a = new Text('$foo $p1');
    var b = new Text('$p2');
    return new Column(
      children: <Widget>[a, b],
    );
  }
}
''');
    _createRefactoringForStringOffset('createColumn(String');

    await _assertSuccessfulRefactoring(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  String foo;

  @override
  Widget build(BuildContext context) {
    int bar = 1;
    return new Row(
      children: <Widget>[
        Test(foo: foo, p1: 'aaa', p2: bar),
        Test(foo: foo, p1: 'bbb', p2: 2),
      ],
    );
  }
}

class Test extends StatelessWidget {
  const Test({
    Key key,
    @required this.foo,
    @required this.p1,
    @required this.p2,
  }) : super(key: key);

  final String foo;
  final String p1;
  final int p2;

  @override
  Widget build(BuildContext context) {
    var a = new Text('$foo $p1');
    var b = new Text('$p2');
    return new Column(
      children: <Widget>[a, b],
    );
  }
}
''');
  }

  test_method_parameters_named() async {
    addFlutterPackage();
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  String foo;

  @override
  Widget build(BuildContext context) {
    int bar = 1;
    return new Row(
      children: <Widget>[
        createColumn(p1: 'aaa', p2: bar),
        createColumn(p1: 'bbb', p2: 2),
      ],
    );
  }
  
  Widget createColumn({String p1, int p2}) {
    var a = new Text('$foo $p1');
    var b = new Text('$p2');
    return new Column(
      children: <Widget>[a, b],
    );
  }
}
''');
    _createRefactoringForStringOffset('createColumn({String');

    await _assertSuccessfulRefactoring(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  String foo;

  @override
  Widget build(BuildContext context) {
    int bar = 1;
    return new Row(
      children: <Widget>[
        Test(foo: foo, p1: 'aaa', p2: bar),
        Test(foo: foo, p1: 'bbb', p2: 2),
      ],
    );
  }
}

class Test extends StatelessWidget {
  const Test({
    Key key,
    @required this.foo,
    @required this.p1,
    @required this.p2,
  }) : super(key: key);

  final String foo;
  final String p1;
  final int p2;

  @override
  Widget build(BuildContext context) {
    var a = new Text('$foo $p1');
    var b = new Text('$p2');
    return new Column(
      children: <Widget>[a, b],
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
    return Test(field: field);
  }
}

class Test extends StatelessWidget {
  const Test({
    Key key,
    @required this.field,
  }) : super(key: key);

  final String field;

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
    return Test(c: c);
  }
}

class Test extends StatelessWidget {
  const Test({
    Key key,
    @required this.c,
  }) : super(key: key);

  final C c;

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
    return Test();
  }
}

class Test extends StatelessWidget {
  const Test({
    Key key,
  }) : super(key: key);

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

  test_parameters_field_write_enclosingSuperClass() async {
    addFlutterPackage();
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

abstract class MySuperWidget extends StatelessWidget {
  String field;
}

class MyWidget extends MySuperWidget {
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
    return Test(c: c);
  }
}

class Test extends StatelessWidget {
  const Test({
    Key key,
    @required this.c,
  }) : super(key: key);

  final C c;

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

  test_parameters_key() async {
    addFlutterPackage();
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String key;
    return new Text('$key $key');
  }
}
''');
    _createRefactoringForStringOffset('new Text');

    RefactoringStatus status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR);
  }

  test_parameters_local_read_enclosingScope() async {
    addFlutterPackage();
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String local;
    return new Text('$local $local');
  }
}
''');
    _createRefactoringForStringOffset('new Text');

    await _assertSuccessfulRefactoring(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String local;
    return Test(local: local);
  }
}

class Test extends StatelessWidget {
  const Test({
    Key key,
    @required this.local,
  }) : super(key: key);

  final String local;

  @override
  Widget build(BuildContext context) {
    return new Text('$local $local');
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

  test_parameters_private() async {
    addFlutterPackage();
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  String _field;

  @override
  Widget build(BuildContext context) {
    return new Text(_field);
  }
}
''');
    _createRefactoringForStringOffset('new Text');

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  String _field;

  @override
  Widget build(BuildContext context) {
    return Test(field: _field);
  }
}

class Test extends StatelessWidget {
  const Test({
    Key key,
    @required String field,
  }) : _field = field, super(key: key);

  final String _field;

  @override
  Widget build(BuildContext context) {
    return new Text(_field);
  }
}
''');
  }

  test_parameters_private_conflictWithPublic() async {
    addFlutterPackage();
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  int field;
  String _field;

  @override
  Widget build(BuildContext context) {
    return new Text('$field $_field');
  }
}
''');
    _createRefactoringForStringOffset('new Text');

    await _assertSuccessfulRefactoring(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  int field;
  String _field;

  @override
  Widget build(BuildContext context) {
    return Test(field: field, field2: _field);
  }
}

class Test extends StatelessWidget {
  const Test({
    Key key,
    @required this.field,
    @required String field2,
  }) : _field = field2, super(key: key);

  final int field;
  final String _field;

  @override
  Widget build(BuildContext context) {
    return new Text('$field $_field');
  }
}
''');
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
    return Test(field: field, local: local);
  }
}

class Test extends StatelessWidget {
  const Test({
    Key key,
    @required this.field,
    @required this.local,
  }) : super(key: key);

  final String field;
  final String local;

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

  test_statements() async {
    addFlutterPackage();
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

Widget main() {
  var index = 0;
  var a = 'a $index';
// start
  var b = 'b $index';
  return new Row(
    children: <Widget>[
      new Text(a),
      new Text(b),
    ],
  );
// end
}
''');
    _createRefactoringForStartEnd();

    await _assertSuccessfulRefactoring(r'''
import 'package:flutter/material.dart';

Widget main() {
  var index = 0;
  var a = 'a $index';
// start
  return Test(index: index, a: a);
// end
}

class Test extends StatelessWidget {
  const Test({
    Key key,
    @required this.index,
    @required this.a,
  }) : super(key: key);

  final int index;
  final String a;

  @override
  Widget build(BuildContext context) {
    var b = 'b $index';
    return new Row(
      children: <Widget>[
        new Text(a),
        new Text(b),
      ],
    );
  }
}
''');
  }

  test_statements_BAD_emptySelection() async {
    addFlutterPackage();
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

void main() {
// start
// end
}
''');
    _createRefactoringForStartEnd();

    assertRefactoringStatus(await refactoring.checkInitialConditions(),
        RefactoringProblemSeverity.FATAL);
  }

  test_statements_BAD_notReturnStatement() async {
    addFlutterPackage();
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

void main() {
// start
  new Text('text');
// end
}
''');
    _createRefactoringForStartEnd();

    assertRefactoringStatus(await refactoring.checkInitialConditions(),
        RefactoringProblemSeverity.FATAL);
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

  void _createRefactoring(int offset, int length) {
    refactoring = new ExtractWidgetRefactoring(
        searchEngine, testAnalysisResult, offset, length);
    refactoring.name = 'Test';
  }

  void _createRefactoringForStartEnd() {
    int offset = findOffset('// start\n') + '// start\n'.length;
    int length = findOffset('// end') - offset;
    _createRefactoring(offset, length);
  }

  /**
   * Creates a new refactoring in [refactoring] at the offset of the given
   * [search] pattern.
   */
  void _createRefactoringForStringOffset(String search) {
    int offset = findOffset(search);
    _createRefactoring(offset, 0);
  }
}
