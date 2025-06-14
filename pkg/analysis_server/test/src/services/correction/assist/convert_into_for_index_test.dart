// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertIntoForIndexTest);
  });
}

@reflectiveTest
class ConvertIntoForIndexTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.convertIntoForIndex;

  Future<void> test_bodyNotBlock() async {
    await resolveTestCode('''
void f(List<String> items) {
  f^or (String item in items) print(item);
}
''');
    await assertNoAssist();
  }

  Future<void> test_doesNotDeclareVariable() async {
    await resolveTestCode('''
void f(List<String> items) {
  String item;
  ^for (item in items) {
    print(item);
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_iterableIsNotVariable() async {
    await resolveTestCode('''
void f() {
  fo^r (String item in ['a', 'b', 'c']) {
    print(item);
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_iterableNotList() async {
    await resolveTestCode('''
void f(Iterable<String> items) {
  ^for (String item in items) {
    print(item);
  }
}
''');
    await assertNoAssist();
  }

  Future<void> test_onDeclaredIdentifier_name() async {
    await resolveTestCode('''
void f(List<String> items) {
  for (String ^item in items) {
    print(item);
  }
}
''');
    await assertHasAssist('''
void f(List<String> items) {
  for (int i = 0; i < items.length; i++) {
    String item = items[i];
    print(item);
  }
}
''');
  }

  Future<void> test_onDeclaredIdentifier_type() async {
    await resolveTestCode('''
void f(List<String> items) {
  for (S^tring item in items) {
    print(item);
  }
}
''');
    await assertHasAssist('''
void f(List<String> items) {
  for (int i = 0; i < items.length; i++) {
    String item = items[i];
    print(item);
  }
}
''');
  }

  Future<void> test_onFor() async {
    await resolveTestCode('''
void f(List<String> items) {
  f^or (String item in items) {
    print(item);
  }
}
''');
    await assertHasAssist('''
void f(List<String> items) {
  for (int i = 0; i < items.length; i++) {
    String item = items[i];
    print(item);
  }
}
''');
  }

  Future<void> test_usesI() async {
    await resolveTestCode('''
void f(List<String> items) {
  fo^r (String item in items) {
    int i = 0;
  }
}
''');
    await assertHasAssist('''
void f(List<String> items) {
  for (int j = 0; j < items.length; j++) {
    String item = items[j];
    int i = 0;
  }
}
''');
  }

  Future<void> test_usesIJ() async {
    await resolveTestCode('''
void f(List<String> items) {
  fo^r (String item in items) {
    print(item);
    int i = 0, j = 1;
  }
}
''');
    await assertHasAssist('''
void f(List<String> items) {
  for (int k = 0; k < items.length; k++) {
    String item = items[k];
    print(item);
    int i = 0, j = 1;
  }
}
''');
  }

  Future<void> test_usesIJK() async {
    await resolveTestCode('''
void f(List<String> items) {
  ^for (String item in items) {
    print(item);
    int i, j, k;
  }
}
''');
    await assertNoAssist();
  }
}
