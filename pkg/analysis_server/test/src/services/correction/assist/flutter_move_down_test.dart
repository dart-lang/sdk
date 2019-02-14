// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterMoveDownTest);
  });
}

@reflectiveTest
class FlutterMoveDownTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.FLUTTER_MOVE_DOWN;

  test_first() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
main() {
  new Column(
    children: <Widget>[
      new Text('aaa'),
      /*caret*/new Text('bbbbbb'),
      new Text('ccccccccc'),
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
      /*caret*/new Text('ccccccccc'),
      new Text('bbbbbb'),
    ],
  );
}
''');
    assertExitPosition(before: "new Text('bbbbbb')");
  }

  test_last() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
main() {
  new Column(
    children: <Widget>[
      new Text('aaa'),
      new Text('bbb'),
      /*caret*/new Text('ccc'),
    ],
  );
}
''');
    await assertNoAssist();
  }

  test_notInList() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
main() {
  new Center(
    child: /*caret*/new Text('aaa'),
  );
}
''');
    await assertNoAssist();
  }
}
