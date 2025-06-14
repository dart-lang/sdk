// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterSwapWithParentTest);
  });
}

@reflectiveTest
class FlutterSwapWithParentTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.flutterSwapWithParent;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_inCenter() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
build() {
  return Scaffold(
    body: Center(
      child: ^GestureDetector(
        onTap: () => startResize(),
        child: Container(
          width: 200.0,
          height: 300.0,
        ),
      ),
      key: Key('x'),
    ),
  );
}
startResize() {}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
build() {
  return Scaffold(
    body: GestureDetector(
      onTap: () => startResize(),
      child: Center(
        key: Key('x'),
        child: Container(
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

  Future<void> test_notFormatted() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';

class Foo extends StatefulWidget {
  @override
  State<Foo> createState() => _State();
}

class _State extends State<Foo> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: ^Expanded(
        child: Text(
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
  State<Foo> createState() => _State();
}

class _State extends State<Foo> {
  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: 2,
      child: GestureDetector(
        onTap: () {
          print(42);
      },
        child: Text(
          'foo',
        ),
      ),
    );
  }
}''');
  }

  Future<void> test_outerIsInChildren() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
void f() {
  Column(
    children: [
      Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.0),
            child: ^Center(
              child: Column(
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
void f() {
  Column(
    children: [
      Column(
        children: [
          Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
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

  Future<void> test_single_child_multi() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
build() {
  return Scaffold(
    body: Column(
      children: [
        ^Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Hello'),
        ),
      ],
    ),
  );
}
startResize() {}
''');
    await assertHasAssist('''
import 'package:flutter/material.dart';
build() {
  return Scaffold(
    body: Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          Text('Hello'),
        ],
      ),
    ),
  );
}
startResize() {}
''');
  }

  Future<void> test_two_children_multi() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
build() {
  return Scaffold(
    body: Column(
      children: [
        ^Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Hello'),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Text('Hello'),
        ),
      ],
    ),
  );
}
startResize() {}
''');
    await assertNoAssist();
  }
}
