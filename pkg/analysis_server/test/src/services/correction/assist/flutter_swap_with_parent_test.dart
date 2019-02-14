// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterSwapWithParentTest);
  });
}

@reflectiveTest
class FlutterSwapWithParentTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.FLUTTER_SWAP_WITH_PARENT;

  test_inCenter() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
build() {
  return new Scaffold(
    body: new Center(
      child: new /*caret*/GestureDetector(
        onTap: () => startResize(),
        child: new Container(
          width: 200.0,
          height: 300.0,
        ),
      ),
      key: null,
    ),
  );
}
startResize() {}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
build() {
  return new Scaffold(
    body: new /*caret*/GestureDetector(
      onTap: () => startResize(),
      child: new Center(
        key: null,
        child: new Container(
          width: 200.0,
          height: 300.0,
        ),
      ),
    ),
  );
}
startResize() {}
''');
  }

  test_notFormatted() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';

class Foo extends StatefulWidget {
  @override
  _State createState() => new _State();
}

class _State extends State<Foo> {
  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      child: new /*caret*/Expanded(
        child: new Text(
          'foo',
        ),
        flex: 2,
      ), onTap: () {
        print(42);
    },
    );
  }
}''');
    await assertHasAssist('''
import 'package:flutter/material.dart';

class Foo extends StatefulWidget {
  @override
  _State createState() => new _State();
}

class _State extends State<Foo> {
  @override
  Widget build(BuildContext context) {
    return new /*caret*/Expanded(
      flex: 2,
      child: new GestureDetector(
        onTap: () {
          print(42);
      },
        child: new Text(
          'foo',
        ),
      ),
    );
  }
}''');
  }

  test_outerIsInChildren() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
main() {
  new Column(
    children: [
      new Column(
        children: [
          new Padding(
            padding: new EdgeInsets.all(16.0),
            child: new /*caret*/Center(
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[],
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
main() {
  new Column(
    children: [
      new Column(
        children: [
          new /*caret*/Center(
            child: new Padding(
              padding: new EdgeInsets.all(16.0),
              child: new Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[],
              ),
            ),
          ),
        ],
      ),
    ],
  );
}
''');
  }
}
