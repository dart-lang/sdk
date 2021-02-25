// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterSwapWithChildTest);
  });
}

@reflectiveTest
class FlutterSwapWithChildTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.FLUTTER_SWAP_WITH_CHILD;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(
      flutter: true,
    );
  }

  Future<void> test_aroundCenter() async {
    await resolveTestCode('''
import 'package:flutter/material.dart';
build() {
  return Scaffold(
    body: /*caret*/GestureDetector(
      onTap: () => startResize(),
      child: Center(
        child: Container(
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
  return Scaffold(
    body: Center(
      key: null,
      child: GestureDetector(
        onTap: () => startResize(),
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
  _State createState() => _State();
}

class _State extends State<Foo> {
  @override
  Widget build(BuildContext context) {
    return /*caret*/Expanded(
      flex: 2,
      child: GestureDetector(
        child: Text(
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
  _State createState() => _State();
}

class _State extends State<Foo> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print(42);
    },
      child: Expanded(
        flex: 2,
        child: Text(
          'foo',
        ),
      ),
    );
  }
}''');
  }
}
