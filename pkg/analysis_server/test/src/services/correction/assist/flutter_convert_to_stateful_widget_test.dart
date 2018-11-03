// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterConvertToStatefulWidgetTest);
  });
}

@reflectiveTest
class FlutterConvertToStatefulWidgetTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.FLUTTER_CONVERT_TO_STATEFUL_WIDGET;

  test_empty() async {
    addFlutterPackage();
    await resolveTestUnit(r'''
import 'package:flutter/material.dart';

class /*caret*/MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Container();
  }
}
''');
    await assertHasAssist(r'''
import 'package:flutter/material.dart';

class /*caret*/MyWidget extends StatefulWidget {
  @override
  MyWidgetState createState() {
    return new MyWidgetState();
  }
}

class MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return new Container();
  }
}
''');
  }

  test_fields() async {
    addFlutterPackage();
    await resolveTestUnit(r'''
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
    return new Row(
      children: [
        new Text(instanceField1),
        new Text(instanceField2),
        new Text(instanceField3),
        new Text(instanceField4),
        new Text(instanceField5),
        new Text(staticField1),
        new Text(staticField2),
        new Text(staticField3),
      ],
    );
  }
}
''');
    await assertHasAssist(r'''
import 'package:flutter/material.dart';

class /*caret*/MyWidget extends StatefulWidget {
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
  MyWidgetState createState() {
    return new MyWidgetState();
  }
}

class MyWidgetState extends State<MyWidget> {
  String instanceField4;

  String instanceField5;

  @override
  Widget build(BuildContext context) {
    instanceField4 = widget.instanceField1;
    return new Row(
      children: [
        new Text(widget.instanceField1),
        new Text(widget.instanceField2),
        new Text(widget.instanceField3),
        new Text(instanceField4),
        new Text(instanceField5),
        new Text(MyWidget.staticField1),
        new Text(MyWidget.staticField2),
        new Text(MyWidget.staticField3),
      ],
    );
  }
}
''');
  }

  test_getters() async {
    addFlutterPackage();
    await resolveTestUnit(r'''
import 'package:flutter/material.dart';

class /*caret*/MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Row(
      children: [
        new Text(staticGetter1),
        new Text(staticGetter2),
        new Text(instanceGetter1),
        new Text(instanceGetter2),
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

class /*caret*/MyWidget extends StatefulWidget {
  @override
  MyWidgetState createState() {
    return new MyWidgetState();
  }

  static String get staticGetter1 => '';

  static String get staticGetter2 => '';
}

class MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return new Row(
      children: [
        new Text(MyWidget.staticGetter1),
        new Text(MyWidget.staticGetter2),
        new Text(instanceGetter1),
        new Text(instanceGetter2),
      ],
    );
  }

  String get instanceGetter1 => '';

  String get instanceGetter2 => '';
}
''');
  }

  test_methods() async {
    addFlutterPackage();
    await resolveTestUnit(r'''
import 'package:flutter/material.dart';

class /*caret*/MyWidget extends StatelessWidget {
  static String staticField;
  final String instanceField1;
  String instanceField2;

  MyWidget(this.instanceField1);

  @override
  Widget build(BuildContext context) {
    return new Row(
      children: [
        new Text(instanceField1),
        new Text(instanceField2),
        new Text(staticField),
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

class /*caret*/MyWidget extends StatefulWidget {
  static String staticField;
  final String instanceField1;

  MyWidget(this.instanceField1);

  @override
  MyWidgetState createState() {
    return new MyWidgetState();
  }

  static void staticMethod1() {
    print('static 1');
  }

  static void staticMethod2() {
    print('static 2');
  }
}

class MyWidgetState extends State<MyWidget> {
  String instanceField2;

  @override
  Widget build(BuildContext context) {
    return new Row(
      children: [
        new Text(widget.instanceField1),
        new Text(instanceField2),
        new Text(MyWidget.staticField),
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

  test_notClass() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
/*caret*/main() {}
''');
    assertNoAssist();
  }

  test_notStatelessWidget() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
class /*caret*/MyWidget extends Text {
  MyWidget() : super('');
}
''');
    assertNoAssist();
  }

  test_notWidget() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
class /*caret*/MyWidget {}
''');
    assertNoAssist();
  }

  test_simple() async {
    addFlutterPackage();
    await resolveTestUnit(r'''
import 'package:flutter/material.dart';

class /*caret*/MyWidget extends StatelessWidget {
  final String aaa;
  final String bbb;

  const MyWidget(this.aaa, this.bbb);

  @override
  Widget build(BuildContext context) {
    return new Row(
      children: [
        new Text(aaa),
        new Text(bbb),
        new Text('$aaa'),
        new Text('${bbb}'),
      ],
    );
  }
}
''');
    await assertHasAssist(r'''
import 'package:flutter/material.dart';

class /*caret*/MyWidget extends StatefulWidget {
  final String aaa;
  final String bbb;

  const MyWidget(this.aaa, this.bbb);

  @override
  MyWidgetState createState() {
    return new MyWidgetState();
  }
}

class MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return new Row(
      children: [
        new Text(widget.aaa),
        new Text(widget.bbb),
        new Text('${widget.aaa}'),
        new Text('${widget.bbb}'),
      ],
    );
  }
}
''');
  }

  test_tail() async {
    addFlutterPackage();
    await resolveTestUnit(r'''
import 'package:flutter/material.dart';

class /*caret*/MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Container();
  }
}
''');
    await assertHasAssist(r'''
import 'package:flutter/material.dart';

class /*caret*/MyWidget extends StatefulWidget {
  @override
  MyWidgetState createState() {
    return new MyWidgetState();
  }
}

class MyWidgetState extends State<MyWidget> {
  @override
  Widget build(BuildContext context) {
    return new Container();
  }
}
''');
  }
}
