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
  AssistKind get kind => DartAssistKind.SURROUND_WITH_SET_STATE;

  Future<void> test_outsideState() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';

class Stateless {
  int _count1;
  int _count2;
  
  void increment() {
// start
    ++_count1;
    ++_count2;
// end
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_stateSubclass() async {
    addFlutterPackage();
    await resolveTestUnit('''
import 'package:flutter/widgets.dart';

class MyState extends State {
  int _count1;
  int _count2;

  void increment() {
// start
    ++_count1;
    ++_count2;
// end
  }
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';

class MyState extends State {
  int _count1;
  int _count2;

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
