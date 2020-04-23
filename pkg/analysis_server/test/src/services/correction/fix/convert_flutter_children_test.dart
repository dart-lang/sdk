// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertFlutterChildrenTest);
  });
}

@reflectiveTest
class ConvertFlutterChildrenTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.CONVERT_FLUTTER_CHILDREN;

  Future<void> test_undefinedParameter_multiLine() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
build() {
  return new Center(
    children: [
      new Container(
        width: 200.0,
        height: 300.0,
      ),
    ],
  );
}
''');
    await assertHasFix('''
import 'package:flutter/widgets.dart';
build() {
  return new Center(
    child: new Container(
      width: 200.0,
      height: 300.0,
    ),
  );
}
''');
  }

  Future<void> test_undefinedParameter_notWidget() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
build() {
  return new Center(
    children: [
      new Object(),
    ],
  );
}
''');
    await assertNoFix();
  }

  Future<void> test_undefinedParameter_singleLine() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
build() {
  return new Center(
    children: [
      new Text('foo'),
    ],
  );
}
''');
    await assertHasFix('''
import 'package:flutter/widgets.dart';
build() {
  return new Center(
    child: new Text('foo'),
  );
}
''');
  }

  Future<void> test_undefinedParameter_singleLine2() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';
build() {
  var text = new Text('foo');
  new Center(
    children: [text],
  );
}
''');
    await assertHasFix('''
import 'package:flutter/widgets.dart';
build() {
  var text = new Text('foo');
  new Center(
    child: text,
  );
}
''');
  }
}
