// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertFlutterChildTest);
  });
}

@reflectiveTest
class ConvertFlutterChildTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_FLUTTER_CHILD;

  Future<void> test_hasList() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
build() {
  return Container(
    child: Row(
      child: [
        Text('111'),
        Text('222'),
      ],
    ),
  );
}
''');
    await assertHasFix('''
import 'package:flutter/widgets.dart';
build() {
  return Container(
    child: Row(
      children: [
        Text('111'),
        Text('222'),
      ],
    ),
  );
}
''');
  }

  Future<void> test_hasTypedList() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
build() {
  return new Container(
    child: new Row(
      child: <Widget>[
        new Text('111'),
        new Text('222'),
      ],
    ),
  );
}
''');
    await assertHasFix('''
import 'package:flutter/widgets.dart';
build() {
  return new Container(
    child: new Row(
      children: <Widget>[
        new Text('111'),
        new Text('222'),
      ],
    ),
  );
}
''');
  }

  Future<void> test_listNotWidget() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
build() {
  return new Container(
    child: new Row(
      child: [
        new Container(),
        null,
      ],
    ),
  );
}
''');
    await assertNoFix();
  }

  Future<void> test_multiLine() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
build() {
  return new Scaffold(
    body: new Row(
      child: new Container(
        width: 200.0,
        height: 300.0,
      ),
    ),
  );
}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';
build() {
  return new Scaffold(
    body: new Row(
      children: [
        new Container(
          width: 200.0,
          height: 300.0,
        ),
      ],
    ),
  );
}
''');
  }

  Future<void> test_widgetVariable() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
build() {
  var text = new Text('foo');
  new Row(
    child: text,
  );
}
''');
    await assertHasFix('''
import 'package:flutter/material.dart';
build() {
  var text = new Text('foo');
  new Row(
    children: [text],
  );
}
''');
  }
}
