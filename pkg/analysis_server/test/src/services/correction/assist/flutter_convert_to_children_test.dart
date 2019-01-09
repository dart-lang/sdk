// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterConvertToChildrenTest);
  });
}

@reflectiveTest
class FlutterConvertToChildrenTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.FLUTTER_CONVERT_TO_CHILDREN;

  test_childUnresolved() async {
    addFlutterPackage();
    verifyNoTestUnitErrors = false;
    await resolveTestUnit('''
import 'package:flutter/material.dart';
build() {
  return new Row(
    /*caret*/child: new Container()
  );
}
''');
    await assertNoAssist();
  }

  test_multiLine() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
build() {
  return new Scaffold(
// start
    body: new Center(
      /*caret*/child: new Container(
        width: 200.0,
        height: 300.0,
      ),
      key: null,
    ),
// end
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
build() {
  return new Scaffold(
// start
    body: new Center(
      /*caret*/children: <Widget>[
        new Container(
          width: 200.0,
          height: 300.0,
        ),
      ],
      key: null,
    ),
// end
  );
}
''');
  }

  test_newlineChild() async {
    // This case could occur with deeply nested constructors, common in Flutter.
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
build() {
  return new Scaffold(
// start
    body: new Center(
      /*caret*/child:
          new Container(
        width: 200.0,
        height: 300.0,
      ),
      key: null,
    ),
// end
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
build() {
  return new Scaffold(
// start
    body: new Center(
      /*caret*/children: <Widget>[
        new Container(
          width: 200.0,
          height: 300.0,
        ),
      ],
      key: null,
    ),
// end
  );
}
''');
  }

  test_notOnChild() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
build() {
  return new Scaffold(
    body: /*caret*/new Center(
      child: new Container(),
    ),
  );
}
''');
    await assertNoAssist();
  }

  test_singleLine() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
build() {
  return new Scaffold(
// start
    body: new Center(
      /*caret*/child: new GestureDetector(),
      key: null,
    ),
// end
  );
}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
build() {
  return new Scaffold(
// start
    body: new Center(
      /*caret*/children: <Widget>[new GestureDetector()],
      key: null,
    ),
// end
  );
}
''');
  }
}
