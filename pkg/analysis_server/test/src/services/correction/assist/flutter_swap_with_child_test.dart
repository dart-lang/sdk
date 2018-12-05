// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterSwapWithChildTest);
  });
}

@reflectiveTest
class FlutterSwapWithChildTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.FLUTTER_SWAP_WITH_CHILD;

  test_aroundCenter() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/material.dart';
build() {
  return new Scaffold(
    body: new /*caret*/GestureDetector(
      onTap: () => startResize(),
      child: new Center(
        child: new Container(
          width: 200.0,
          height: 300.0,
        ),
        key: null,
      ),
    ),
  );
}
startResize() {}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
build() {
  return new Scaffold(
    body: new Center(
      key: null,
      child: new /*caret*/GestureDetector(
        onTap: () => startResize(),
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
    return new /*caret*/Expanded(
      flex: 2,
      child: new GestureDetector(
        child: new Text(
          'foo',
        ), onTap: () {
          print(42);
      },
      ),
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
    return new GestureDetector(
      onTap: () {
        print(42);
    },
      child: new /*caret*/Expanded(
        flex: 2,
        child: new Text(
          'foo',
        ),
      ),
    );
  }
}''');
  }
}
