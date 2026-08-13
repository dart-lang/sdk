// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveUnnecessaryNameTest);
  });
}

@reflectiveTest
class RemoveUnnecessaryNameTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.removeUnnecessaryName;

  Future<void> test_objectDestructuring() async {
    await resolveTestCode('''
void f(int value) {
  var int(isEven: is^Even) = value;
  print(isEven);
}
''');
    await assertHasAssist('''
void f(int value) {
  var int(: is^Even) = value;
  print(isEven);
}
''');
  }

  Future<void> test_objectPatternField_explicit() async {
    await resolveTestCode('''
void f(Object o) {
  if (o case int(isEv^en:var isEven) when isEven) {}
}
''');
    await assertHasAssist('''
void f(Object o) {
  if (o case int(:var isEven) when isEven) {}
}
''');
  }

  Future<void> test_objectPatternField_otherName() async {
    await resolveTestCode('''
void f(Object o) {
  if (o case int(isEv^en:var other) when other) {}
}
''');
    await assertNoAssist();
  }

  Future<void> test_recordDestructuring() async {
    await resolveTestCode('''
void f((int, {String name}) record) {
  var (x, name: na^me) = record;
  print(name);
}
''');
    await assertHasAssist('''
void f((int, {String name}) record) {
  var (x, : name) = record;
  print(name);
}
''');
  }

  Future<void> test_recordPatternField_explicit() async {
    await resolveTestCode('''
void f(({bool isEven,}) o) {
  if (o case (isEv^en:var isEven) when isEven) {}
}
''');
    await assertHasAssist('''
void f(({bool isEven,}) o) {
  if (o case (:var isEven) when isEven) {}
}
''');
  }
}
