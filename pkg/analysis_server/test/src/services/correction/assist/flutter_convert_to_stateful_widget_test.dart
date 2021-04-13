// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterConvertToStatefulWidgetTest);
  });
}

@reflectiveTest
class FlutterConvertToStatefulWidgetTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.FLUTTER_CONVERT_TO_STATEFUL_WIDGET;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      flutter: true,
    );
  }

  Future<void> test_empty() async {
    await resolveTestCode(r'''
import 'package:flutter/material.dart';

class /*caret*/MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''');
    await assertHasAssist(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''');
  }

  Future<void> test_empty_typeParam() async {
    await resolveTestCode(r'''
import 'package:flutter/material.dart';

class /*caret*/MyWidget<T> extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''');
    await assertHasAssist(r'''
import 'package:flutter/material.dart';

class MyWidget<T> extends StatefulWidget {
  @override
  _MyWidgetState<T> createState() => _MyWidgetState<T>();
}

class _MyWidgetState<T> extends State<MyWidget<T>> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''');
  }

  Future<void> test_fields() async {
    await resolveTestCode(r'''
import 'package:flutter/material.dart';

class /*caret*/MyWidget extends StatelessWidget {
  static String staticField1;
  final String instanceField1;
  final String instanceField2;
  String instanceField3;
  static String staticField2;
  String instanceField4;
  String instanceField5;
  static String staticField3;

  MyWidget(this.instanceField1) : instanceField2 = '' {
    instanceField3 = '';
  }

  @override
  Widget build(BuildContext context) {
    instanceField4 = instanceField1;
    return Row(
      children: [
        Text(instanceField1),
        Text(instanceField2),
        Text(instanceField3),
        Text(instanceField4),
        Text(instanceField5),
        Text(staticField1),
        Text(staticField2),
        Text(staticField3),
      ],
    );
  }
}
''');
    await assertHasAssist(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  static String staticField1;
  final String instanceField1;
  final String instanceField2;
  String instanceField3;
  static String staticField2;
  static String staticField3;

  MyWidget(this.instanceField1) : instanceField2 = '' {
    instanceField3 = '';
  }

  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  String instanceField4;

  String instanceField5;

  @override
  Widget build(BuildContext context) {
    instanceField4 = widget.instanceField1;
    return Row(
      children: [
        Text(widget.instanceField1),
        Text(widget.instanceField2),
        Text(widget.instanceField3),
        Text(instanceField4),
        Text(instanceField5),
        Text(MyWidget.staticField1),
        Text(MyWidget.staticField2),
        Text(MyWidget.staticField3),
      ],
    );
  }
}
''');
  }

  Future<void> test_getters() async {
    await resolveTestCode(r'''
import 'package:flutter/material.dart';

class /*caret*/MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(staticGetter1),
        Text(staticGetter2),
        Text(instanceGetter1),
        Text(instanceGetter2),
      ],
    );
  }

  static String get staticGetter1 => '';

  String get instanceGetter1 => '';

  static String get staticGetter2 => '';

  String get instanceGetter2 => '';
}
''');
    await assertHasAssist(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();

  static String get staticGetter1 => '';

  static String get staticGetter2 => '';
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(MyWidget.staticGetter1),
        Text(MyWidget.staticGetter2),
        Text(instanceGetter1),
        Text(instanceGetter2),
      ],
    );
  }

  String get instanceGetter1 => '';

  String get instanceGetter2 => '';
}
''');
  }

  Future<void> test_methods() async {
    await resolveTestCode(r'''
import 'package:flutter/material.dart';

class /*caret*/MyWidget extends StatelessWidget {
  static String staticField;
  final String instanceField1;
  String instanceField2;

  MyWidget(this.instanceField1);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(instanceField1),
        Text(instanceField2),
        Text(staticField),
      ],
    );
  }

  void instanceMethod1() {
    instanceMethod1();
    instanceMethod2();
    staticMethod1();
  }

  static void staticMethod1() {
    print('static 1');
  }

  void instanceMethod2() {
    print('instance 2');
  }

  static void staticMethod2() {
    print('static 2');
  }
}
''');
    await assertHasAssist(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  static String staticField;
  final String instanceField1;

  MyWidget(this.instanceField1);

  @override
  _MyWidgetState createState() => _MyWidgetState();

  static void staticMethod1() {
    print('static 1');
  }

  static void staticMethod2() {
    print('static 2');
  }
}

class _MyWidgetState extends State<MyWidget> {
  String instanceField2;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(widget.instanceField1),
        Text(instanceField2),
        Text(MyWidget.staticField),
      ],
    );
  }

  void instanceMethod1() {
    instanceMethod1();
    instanceMethod2();
    MyWidget.staticMethod1();
  }

  void instanceMethod2() {
    print('instance 2');
  }
}
''');
  }

  Future<void> test_notClass() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
/*caret*/main() {}
''');
    await assertNoAssist();
  }

  Future<void> test_notStatelessWidget() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
class /*caret*/MyWidget extends Text {
  MyWidget() : super('');
}
''');
    await assertNoAssist();
  }

  Future<void> test_notWidget() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
class /*caret*/MyWidget {}
''');
    await assertNoAssist();
  }

  Future<void> test_simple() async {
    await resolveTestCode(r'''
import 'package:flutter/material.dart';

class /*caret*/MyWidget extends StatelessWidget {
  final String aaa;
  final String bbb;

  const MyWidget(this.aaa, this.bbb);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(aaa),
        Text(bbb),
        Text('$aaa'),
        Text('${bbb}'),
      ],
    );
  }
}
''');
    await assertHasAssist(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  final String aaa;
  final String bbb;

  const MyWidget(this.aaa, this.bbb);

  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(widget.aaa),
        Text(widget.bbb),
        Text('${widget.aaa}'),
        Text('${widget.bbb}'),
      ],
    );
  }
}
''');
  }

  Future<void> test_tail() async {
    await resolveTestCode(r'''
import 'package:flutter/material.dart';

class /*caret*/MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''');
    await assertHasAssist(r'''
import 'package:flutter/material.dart';

class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
''');
  }
}
