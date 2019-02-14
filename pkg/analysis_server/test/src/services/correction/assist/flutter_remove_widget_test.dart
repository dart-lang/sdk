// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterRemoveWidgetTest);
  });
}

@reflectiveTest
class FlutterRemoveWidgetTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.FLUTTER_REMOVE_WIDGET;

  test_childIntoChild_multiLine() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
main() {
  new Column(
    children: <Widget>[
      new Center(
        child: new /*caret*/Padding(
          padding: const EdgeInsets.all(8.0),
          child: new Center(
            heightFactor: 0.5,
            child: new Text('foo'),
          ),
        ),
      ),
    ],
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
main() {
  new Column(
    children: <Widget>[
      new Center(
        child: new Center(
          heightFactor: 0.5,
          child: new Text('foo'),
        ),
      ),
    ],
  );
}
''');
  }

  test_childIntoChild_singleLine() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
main() {
  new Padding(
    padding: const EdgeInsets.all(8.0),
    child: new /*caret*/Center(
      heightFactor: 0.5,
      child: new Text('foo'),
    ),
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
main() {
  new Padding(
    padding: const EdgeInsets.all(8.0),
    child: new Text('foo'),
  );
}
''');
  }

  test_childIntoChildren() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
main() {
  new Column(
    children: <Widget>[
      new Text('foo'),
      new /*caret*/Center(
        heightFactor: 0.5,
        child: new Padding(
          padding: const EdgeInsets.all(8.0),
          child: new Text('bar'),
        ),
      ),
      new Text('baz'),
    ],
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
main() {
  new Column(
    children: <Widget>[
      new Text('foo'),
      new Padding(
        padding: const EdgeInsets.all(8.0),
        child: new Text('bar'),
      ),
      new Text('baz'),
    ],
  );
}
''');
  }

  test_childrenMultipleIntoChild() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
main() {
  new Center(
    child: new /*caret*/Row(
      children: [
        new Text('aaa'),
        new Text('bbb'),
      ],
    ),
  );
}
''');
    await assertNoAssist();
  }

  test_childrenOneIntoChild() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
main() {
  new Center(
    child: /*caret*/new Column(
      children: [
        new Text('foo'),
      ],
    ),
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
main() {
  new Center(
    child: /*caret*/new Text('foo'),
  );
}
''');
  }

  test_childrenOneIntoReturn() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
main() {
  return /*caret*/new Column(
    children: [
      new Text('foo'),
    ],
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
main() {
  return /*caret*/new Text('foo');
}
''');
  }

  test_intoChildren() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
main() {
  new Column(
    children: <Widget>[
      new Text('aaa'),
      new /*caret*/Column(
        children: [
          new Row(
            children: [
              new Text('bbb'),
              new Text('ccc'),
            ],
          ),
          new Row(
            children: [
              new Text('ddd'),
              new Text('eee'),
            ],
          ),
        ],
      ),
      new Text('fff'),
    ],
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
main() {
  new Column(
    children: <Widget>[
      new Text('aaa'),
      new Row(
        children: [
          new Text('bbb'),
          new Text('ccc'),
        ],
      ),
      new Row(
        children: [
          new Text('ddd'),
          new Text('eee'),
        ],
      ),
      new Text('fff'),
    ],
  );
}
''');
  }
}
