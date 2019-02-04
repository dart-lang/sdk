// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterMoveUpTest);
  });
}

@reflectiveTest
class FlutterMoveUpTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.FLUTTER_MOVE_UP;

  test_first() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
main() {
  Column(
    children: <Widget>[
      /*caret*/Text('aaa'),
      Text('bbb'),
      Text('ccc'),
    ],
  );
}
''');
    await assertNoAssist();
  }

  test_last() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
main() {
  Column(
    children: <Widget>[
      Text('aaa'),
      /*caret*/Text('bbbbbb'),
      Text('ccccccccc'),
    ],
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
main() {
  Column(
    children: <Widget>[
      Text('bbbbbb'),
      Text('aaa'),
      Text('ccccccccc'),
    ],
  );
}
''');
    assertExitPosition(before: "Text('bbbbbb')");
  }

  test_notInList() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
main() {
  Center(
    child: /*caret*/Text('aaa'),
  );
}
''');
    await assertNoAssist();
  }
}
