// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterWrapContainerTest);
  });
}

@reflectiveTest
class FlutterWrapContainerTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.flutterWrapContainer;

  @override
  void setUp() {
    super.setUp();
    writeTestPackageConfig(flutter: true);
  }

  Future<void> test_aroundContainer() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
Widget f() {
  return ^Container();
}
''');
    await assertNoAssist();
  }

  Future<void> test_aroundText() async {
    await resolveTestCode('''
import 'package:flutter/widgets.dart';
void f() {
  ^Text('a');
}
''');
    await assertHasAssist('''
import 'package:flutter/widgets.dart';
void f() {
  Container(child: Text('a'));
}
''');
  }
}
