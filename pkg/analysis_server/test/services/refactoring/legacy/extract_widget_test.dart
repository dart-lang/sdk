// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/refactoring/legacy/extract_widget.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'abstract_refactoring.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ExtractWidgetTest);
  });
}

@reflectiveTest
class ExtractWidgetTest extends RefactoringTest {
  @override
  late ExtractWidgetRefactoringImpl refactoring;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_checkAllConditions_selection() async {
    await indexTestUnit('''
import 'package:flutter/material.dart';
^class C {}
''');
    _createRefactoring();

    var status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.FATAL);
  }

  Future<void> test_checkName() async {
    await indexTestUnit('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ^Text('AAA');
  }
}
''');
    _createRefactoring();

    // empty
    refactoring.name = '';
    assertRefactoringStatus(
      refactoring.checkName(),
      RefactoringProblemSeverity.FATAL,
      expectedMessage: 'Class name must not be empty.',
    );

    // OK
    refactoring.name = 'Test';
    assertRefactoringStatusOK(refactoring.checkName());
  }

  Future<void> test_checkName_alreadyDeclared() async {
    await indexTestUnit('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ^Container();
  }
}

class Test {}
''');
    _createRefactoring();

    refactoring.name = 'Test';
    assertRefactoringStatus(
      refactoring.checkName(),
      RefactoringProblemSeverity.ERROR,
      expectedMessage: "Library already declares class with name 'Test'.",
    );
  }

  Future<void> test_expression() async {
    await indexTestUnit('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        ^Column(
          children: <Widget>[
            Text('AAA'),
            Text('BBB'),
          ],
        ),
        Text('CCC'),
        Text('DDD'),
      ],
    );
  }
}
''');
    _createRefactoring();

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Test(),
        Text('CCC'),
        Text('DDD'),
      ],
    );
  }
}

class Test extends StatelessWidget {
  const Test({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text('AAA'),
        Text('BBB'),
      ],
    );
  }
}
''');
  }

  Future<void> test_expression_localFunction() async {
    await indexTestUnit('''
import 'package:flutter/material.dart';

Widget f() {
  Widget foo() {
    return Row(
      children: <Widget>[
        ^Text('AAA'),
        Text('BBB'),
      ],
    );
  }
  return foo();
}
''');
    _createRefactoring();

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

Widget f() {
  Widget foo() {
    return Row(
      children: <Widget>[
        Test(),
        Text('BBB'),
      ],
    );
  }
  return foo();
}

class Test extends StatelessWidget {
  const Test({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text('AAA');
  }
}
''');
  }

  Future<void> test_expression_onTypeName() async {
    await indexTestUnit('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Con^tainer();
  }
}
''');
    _createRefactoring();

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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''');
  }

  Future<void> test_expression_selection() async {
    await indexTestUnit('''
import 'package:flutter/material.dart';

Widget f() {
  return Container();
}
''');

    Future<void> assertResult(String str) async {
      var offset = findOffset(str);
      _createRefactoringForRange(offset, str.length);

      await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

Widget f() {
  return Test();
}

class Test extends StatelessWidget {
  const Test({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''');
    }

    await assertResult('Container');
    await assertResult('Container(');
    await assertResult('Container()');
    await assertResult('Container();');
    await assertResult('taine');
    await assertResult('tainer');
    await assertResult('tainer(');
    await assertResult('tainer()');
    await assertResult('turn Container');
    await assertResult('return Container()');
    await assertResult('return Container();');
  }

  Future<void> test_expression_topFunction() async {
    await indexTestUnit('''
import 'package:flutter/material.dart';

Widget f() {
  return Row(
    children: <Widget>[
      ^Text('AAA'),
      Text('BBB'),
    ],
  );
}
''');
    _createRefactoring();

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

Widget f() {
  return Row(
    children: <Widget>[
      Test(),
      Text('BBB'),
    ],
  );
}

class Test extends StatelessWidget {
  const Test({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text('AAA');
  }
}
''');
  }

  Future<void> test_invocation_enclosingClass() async {
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ^GestureDetector(
      child: Text(''),
      onTap: () {
        foo();
      },
    );
  }

  void foo() {}
}
''');
    _createRefactoring();

    var status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR);
  }

  Future<void> test_invocation_enclosingSuperClass() async {
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

abstract class MyInterface {
  void foo();
}

abstract class MyWidget extends StatelessWidget implements MyInterface {
  @override
  Widget build(BuildContext context) {
    return ^GestureDetector(
      child: Text(''),
      onTap: () {
        foo();
      },
    );
  }
}
''');
    _createRefactoring();

    var status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR);
  }

  Future<void> test_invocation_otherClass() async {
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class C {
  void foo() {}
}

class MyWidget extends StatelessWidget {
  final C c = C();

  @override
  Widget build(BuildContext context) {
    return ^GestureDetector(
      child: Text(''),
      onTap: () {
        c.foo();
      },
    );
  }
}
''');
    _createRefactoring();

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

class C {
  void foo() {}
}

class MyWidget extends StatelessWidget {
  final C c = C();

  @override
  Widget build(BuildContext context) {
    return Test(c: c);
  }
}

class Test extends StatelessWidget {
  const Test({
    super.key,
    required this.c,
  });

  final C c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Text(''),
      onTap: () {
        c.foo();
      },
    );
  }
}
''');
  }

  Future<void> test_method() async {
    await indexTestUnit('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return createColumn();
  }

  Widget ^createColumn() {
    var a = Text('AAA');
    var b = Text('BBB');
    return Column(
      children: <Widget>[a, b],
    );
  }
}
''');
    _createRefactoring();

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
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    var a = Text('AAA');
    var b = Text('BBB');
    return Column(
      children: <Widget>[a, b],
    );
  }
}
''');
  }

  Future<void> test_method_parameters() async {
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  final String foo = '';

  @override
  Widget build(BuildContext context) {
    int bar = 1;
    return Row(
      children: <Widget>[
        createColumn('aaa', bar),
        createColumn('bbb', 2),
      ],
    );
  }

  Widget ^createColumn(String p1, int p2) {
    var a = Text('$foo $p1');
    var b = Text('$p2');
    return Column(
      children: <Widget>[a, b],
    );
  }
}
''');
    _createRefactoring();

    await _assertSuccessfulRefactoring(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  final String foo = '';

  @override
  Widget build(BuildContext context) {
    int bar = 1;
    return Row(
      children: <Widget>[
        Test(foo: foo, p1: 'aaa', p2: bar),
        Test(foo: foo, p1: 'bbb', p2: 2),
      ],
    );
  }
}

class Test extends StatelessWidget {
  const Test({
    super.key,
    required this.foo,
    required this.p1,
    required this.p2,
  });

  final String foo;
  final String p1;
  final int p2;

  @override
  Widget build(BuildContext context) {
    var a = Text('$foo $p1');
    var b = Text('$p2');
    return Column(
      children: <Widget>[a, b],
    );
  }
}
''');
  }

  Future<void> test_method_parameters_mixedAndReordered() async {
    await indexTestUnit(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Ordered differently to the parameters.
    return myWidget(s: '', b: true, i: 1, null);
  }

  Widget ^myWidget(Null n, {int? i, String? s, required bool b}) => Text('Value: $i$s$b');
}
''');
    _createRefactoring();

    await _assertSuccessfulRefactoring(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    // Ordered differently to the parameters.
    return Test(n: null, i: 1, s: '', b: true);
  }
}

class Test extends StatelessWidget {
  const Test({
    super.key,
    required this.n,
    this.i,
    this.s,
    required this.b,
  });

  final Null n;
  final int? i;
  final String? s;
  final bool b;

  @override
  Widget build(BuildContext context) => Text('Value: $i$s$b');
}
''');
  }

  Future<void> test_method_parameters_namedOptional() async {
    await indexTestUnit(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return myWidget();
  }

  Widget ^myWidget({int? value}) => Text('Value: $value');
}
''');
    _createRefactoring();

    await _assertSuccessfulRefactoring(r'''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Test();
  }
}

class Test extends StatelessWidget {
  const Test({
    super.key,
    this.value,
  });

  final int? value;

  @override
  Widget build(BuildContext context) => Text('Value: $value');
}
''');
  }

  Future<void> test_method_parameters_namedRequired() async {
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  final String foo;

  MyWidget(this.foo);

  @override
  Widget build(BuildContext context) {
    int bar = 1;
    return Row(
      children: <Widget>[
        createColumn(p1: 'aaa', p2: bar),
        createColumn(p1: 'bbb', p2: 2),
      ],
    );
  }

  Widget ^createColumn({required String p1, required int p2}) {
    var a = Text('$foo $p1');
    var b = Text('$p2');
    return Column(
      children: <Widget>[a, b],
    );
  }
}
''');
    _createRefactoring();

    await _assertSuccessfulRefactoring(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  final String foo;

  MyWidget(this.foo);

  @override
  Widget build(BuildContext context) {
    int bar = 1;
    return Row(
      children: <Widget>[
        Test(foo: foo, p1: 'aaa', p2: bar),
        Test(foo: foo, p1: 'bbb', p2: 2),
      ],
    );
  }
}

class Test extends StatelessWidget {
  const Test({
    super.key,
    required this.foo,
    required this.p1,
    required this.p2,
  });

  final String foo;
  final String p1;
  final int p2;

  @override
  Widget build(BuildContext context) {
    var a = Text('$foo $p1');
    var b = Text('$p2');
    return Column(
      children: <Widget>[a, b],
    );
  }
}
''');
  }

  Future<void> test_parameters_field_read_otherClass() async {
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class C {
  String field = '';
}

class MyWidget extends StatelessWidget {
  final C c = C();

  @override
  Widget build(BuildContext context) {
    return ^Text(c.field);
  }
}
''');
    _createRefactoring();

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

class C {
  String field = '';
}

class MyWidget extends StatelessWidget {
  final C c = C();

  @override
  Widget build(BuildContext context) {
    return Test(c: c);
  }
}

class Test extends StatelessWidget {
  const Test({
    super.key,
    required this.c,
  });

  final C c;

  @override
  Widget build(BuildContext context) {
    return Text(c.field);
  }
}
''');
  }

  Future<void> test_parameters_field_read_topLevelVariable() async {
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

String field = '';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ^Text(field);
  }
}
''');
    _createRefactoring();

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

String field = '';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Test();
  }
}

class Test extends StatelessWidget {
  const Test({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text(field);
  }
}
''');
  }

  Future<void> test_parameters_field_write_enclosingClass() async {
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

// ignore: must_be_immutable
class MyWidget extends StatelessWidget {
  String field;

  MyWidget(this.field);

  @override
  Widget build(BuildContext context) {
    return ^GestureDetector(
      child: Text(''),
      onTap: () {
        field = '';
      },
    );
  }
}
''');
    _createRefactoring();

    var status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR);
  }

  Future<void> test_parameters_field_write_enclosingSuperClass() async {
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

// ignore: must_be_immutable
abstract class MySuperWidget extends StatelessWidget {
  String field = '';
}

// ignore: must_be_immutable
class MyWidget extends MySuperWidget {
  @override
  Widget build(BuildContext context) {
    return ^GestureDetector(
      child: Text(''),
      onTap: () {
        field = '';
      },
    );
  }
}
''');
    _createRefactoring();

    var status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR);
  }

  Future<void> test_parameters_field_write_otherClass() async {
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class C {
  String field = '';
}

class MyWidget extends StatelessWidget {
  final C c = C();

  @override
  Widget build(BuildContext context) {
    return ^GestureDetector(
      child: Text(''),
      onTap: () {
        c.field = '';
      },
    );
  }
}
''');
    _createRefactoring();

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

class C {
  String field = '';
}

class MyWidget extends StatelessWidget {
  final C c = C();

  @override
  Widget build(BuildContext context) {
    return Test(c: c);
  }
}

class Test extends StatelessWidget {
  const Test({
    super.key,
    required this.c,
  });

  final C c;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Text(''),
      onTap: () {
        c.field = '';
      },
    );
  }
}
''');
  }

  Future<void> test_parameters_key() async {
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String key = '';
    return ^Text('$key $key');
  }
}
''');
    _createRefactoring();

    var status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR);
  }

  Future<void> test_parameters_local_read_enclosingScope() async {
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String local = '';
    return ^Text('$local $local');
  }
}
''');
    _createRefactoring();

    await _assertSuccessfulRefactoring(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String local = '';
    return Test(local: local);
  }
}

class Test extends StatelessWidget {
  const Test({
    super.key,
    required this.local,
  });

  final String local;

  @override
  Widget build(BuildContext context) {
    return Text('$local $local');
  }
}
''');
  }

  Future<void> test_parameters_local_write_enclosingScope() async {
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    String local;
    return ^GestureDetector(
      child: Text(''),
      onTap: () {
        local = '';
      },
    );
  }
}
''');
    _createRefactoring();

    var status = await refactoring.checkAllConditions();
    assertRefactoringStatus(status, RefactoringProblemSeverity.ERROR);
  }

  Future<void> test_parameters_private() async {
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  final String _field;

  MyWidget(this._field);

  @override
  Widget build(BuildContext context) {
    return ^Text(_field);
  }
}
''');
    _createRefactoring();

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  final String _field;

  MyWidget(this._field);

  @override
  Widget build(BuildContext context) {
    return Test(field: _field);
  }
}

class Test extends StatelessWidget {
  const Test({
    super.key,
    required this._field,
  });

  final String _field;

  @override
  Widget build(BuildContext context) {
    return Text(_field);
  }
}
''');
  }

  Future<void> test_parameters_private_conflictWithPublic() async {
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  final int field;
  final String _field;

  MyWidget(this.field, this._field);

  @override
  Widget build(BuildContext context) {
    return ^Text('$field $_field');
  }
}
''');
    _createRefactoring();

    await _assertSuccessfulRefactoring(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  final int field;
  final String _field;

  MyWidget(this.field, this._field);

  @override
  Widget build(BuildContext context) {
    return Test(field: field, field2: _field);
  }
}

class Test extends StatelessWidget {
  const Test({
    super.key,
    required this.field,
    required String field2,
  }) : _field = field2;

  final int field;
  final String _field;

  @override
  Widget build(BuildContext context) {
    return Text('$field $_field');
  }
}
''');
  }

  Future<void> test_parameters_private_unsupported() async {
    await indexTestUnit(r'''
// @dart=3.10
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  final String _field;

  MyWidget(this._field);

  @override
  Widget build(BuildContext context) {
    return ^Text(_field);
  }
}
''');
    _createRefactoring();

    await _assertSuccessfulRefactoring('''
// @dart=3.10
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  final String _field;

  MyWidget(this._field);

  @override
  Widget build(BuildContext context) {
    return Test(field: _field);
  }
}

class Test extends StatelessWidget {
  const Test({
    super.key,
    required String field,
  }) : _field = field;

  final String _field;

  @override
  Widget build(BuildContext context) {
    return Text(_field);
  }
}
''');
  }

  Future<void> test_parameters_readField_readLocal() async {
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  final String field;

  MyWidget(this.field);

  @override
  Widget build(BuildContext context) {
    String local = '';
    return ^Column(
      children: <Widget>[
        Text(field),
        Text(local),
      ],
    );
  }
}
''');
    _createRefactoring();

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  final String field;

  MyWidget(this.field);

  @override
  Widget build(BuildContext context) {
    String local = '';
    return Test(field: field, local: local);
  }
}

class Test extends StatelessWidget {
  const Test({
    super.key,
    required this.field,
    required this.local,
  });

  final String field;
  final String local;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(field),
        Text(local),
      ],
    );
  }
}
''');
  }

  Future<void> test_refactoringName() async {
    await indexTestUnit('''
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ^Text('AAA');
  }
}
''');
    _createRefactoring();
    expect(refactoring.refactoringName, 'Extract Widget');
  }

  Future<void> test_statements() async {
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

Widget f() {
  var index = 0;
  var a = 'a $index';
  [!var b = 'b $index';
  return Row(
    children: <Widget>[
      Text(a),
      Text(b),
    ],
  );!]
}
''');
    _createRefactoring();

    await _assertSuccessfulRefactoring(r'''
import 'package:flutter/material.dart';

Widget f() {
  var index = 0;
  var a = 'a $index';
  return Test(index: index, a: a);
}

class Test extends StatelessWidget {
  const Test({
    super.key,
    required this.index,
    required this.a,
  });

  final int index;
  final String a;

  @override
  Widget build(BuildContext context) {
    var b = 'b $index';
    return Row(
      children: <Widget>[
        Text(a),
        Text(b),
      ],
    );
  }
}
''');
  }

  Future<void> test_statements_BAD_emptySelection() async {
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

void f() {
  [! !]
}
''');
    _createRefactoring();

    assertRefactoringStatus(
      await refactoring.checkInitialConditions(),
      RefactoringProblemSeverity.FATAL,
    );
  }

  Future<void> test_statements_BAD_notReturnStatement() async {
    await indexTestUnit(r'''
import 'package:flutter/material.dart';

void f() {
  [!Text('text');!]
}
''');
    _createRefactoring();

    assertRefactoringStatus(
      await refactoring.checkInitialConditions(),
      RefactoringProblemSeverity.FATAL,
    );
  }

  Future<void> test_useSuperParameters_disabled() async {
    await indexTestUnit('''
// No super params.
// @dart = 2.15
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        ^Column(
          children: <Widget>[
            Text('AAA'),
            Text('BBB'),
          ],
        ),
        Text('CCC'),
        Text('DDD'),
      ],
    );
  }
}
''');
    _createRefactoring();

    await _assertSuccessfulRefactoring('''
// No super params.
// @dart = 2.15
import 'package:flutter/material.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Test(),
        Text('CCC'),
        Text('DDD'),
      ],
    );
  }
}

class Test extends StatelessWidget {
  const Test({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text('AAA'),
        Text('BBB'),
      ],
    );
  }
}
''');
  }

  Future<void> test_widgetReference_multiple() async {
    await indexTestUnit('''
import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({required this.a, required this.b, super.key});

  final String a;
  final String b;

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      ^Text(widget.a + widget.b),
    ]);
  }
}
''');
    _createRefactoring();

    await _assertSuccessfulRefactoring('''
import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({required this.a, required this.b, super.key});

  final String a;
  final String b;

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Test(widget: widget),
    ]);
  }
}

class Test extends StatelessWidget {
  const Test({
    super.key,
    required this.widget,
  });

  final MyWidget widget;

  @override
  Widget build(BuildContext context) {
    return Text(widget.a + widget.b);
  }
}
''');
  }

  Future<void> _assertRefactoringChange(String expectedCode) async {
    var refactoringChange = await refactoring.createChange();
    this.refactoringChange = refactoringChange;
    assertTestChangeResult(expectedCode);
  }

  /// Checks that all conditions are OK and the result of applying the change
  /// to [testUnit] is [expectedCode].
  Future<void> _assertSuccessfulRefactoring(String expectedCode) async {
    await assertRefactoringConditionsOK();
    await _assertRefactoringChange(expectedCode);
  }

  void _createRefactoring() {
    if (parsedTestCode.ranges.isNotEmpty) {
      if (parsedTestCode.positions.isNotEmpty) {
        fail('Expected either one range or one position.');
      }
      var range = parsedTestCode.range.sourceRange;
      _createRefactoringForRange(range.offset, range.length);
    } else if (parsedTestCode.positions.isNotEmpty) {
      var position = parsedTestCode.position;
      _createRefactoringForRange(position.offset, 0);
    } else {
      fail('Expected either one range or one position.');
    }
  }

  void _createRefactoringForRange(int offset, int length) {
    refactoring = ExtractWidgetRefactoringImpl(
      searchEngine,
      testAnalysisResult,
      offset,
      length,
    );
    refactoring.name = 'Test';
  }
}
