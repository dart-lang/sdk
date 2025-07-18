// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterSurroundWithSetStateTest);
  });
}

@reflectiveTest
class FlutterSurroundWithSetStateTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.surroundWithSetState;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_noParentNode() async {
    // This code selects the `CompilationUnit` node which has previously
    // caused errors in code assuming the node would have a parent.
    await resolveTestCode('''
void f() {
  [!print(0);
}

other() {
  print(1);!]
}
''');
    await assertNoAssist();
  }

  Future<void> test_outsideState() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class Stateless {
  int _count1 = 0;
  int _count2 = 0;

  void increment() {
    [!++_count1;
    ++_count2;!]
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_stateSubclass() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';

class MyState extends State {
  int _count1 = 0;
  int _count2 = 0;

  void increment() {
    [!++_count1;
    ++_count2;!]
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

class MyState extends State {
  int _count1 = 0;
  int _count2 = 0;

  void increment() {
    setState(() {
      ++_count1;
      ++_count2;
    });
  }
}
''');
    assertExitPosition(before: '});');
  }
}
