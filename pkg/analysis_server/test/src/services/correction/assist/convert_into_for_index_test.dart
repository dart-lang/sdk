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
  AssistKind get kind => DartAssistKind.CONVERT_INTO_FOR_INDEX;

  Future<void> test_bodyNotBlock() async {
    await resolveTestCode('''
main(List<String> items) {
  for (String item in items) print(item);
}
''');
    await assertNoAssistAt('for (String');
  }

  Future<void> test_doesNotDeclareVariable() async {
    await resolveTestCode('''
main(List<String> items) {
  String item;
  for (item in items) {
    print(item);
  }
}
''');
    await assertNoAssistAt('for (item');
  }

  Future<void> test_iterableIsNotVariable() async {
    await resolveTestCode('''
main() {
  for (String item in ['a', 'b', 'c']) {
    print(item);
  }
}
''');
    await assertNoAssistAt('for (String');
  }

  Future<void> test_iterableNotList() async {
    await resolveTestCode('''
main(Iterable<String> items) {
  for (String item in items) {
    print(item);
  }
}
''');
    await assertNoAssistAt('for (String');
  }

  Future<void> test_onDeclaredIdentifier_name() async {
    await resolveTestCode('''
main(List<String> items) {
  for (String item in items) {
    print(item);
  }
}
''');
    await assertHasAssistAt('item in', '''
main(List<String> items) {
  for (int i = 0; i < items.length; i++) {
    String item = items[i];
    print(item);
  }
}
''');
  }

  Future<void> test_onDeclaredIdentifier_type() async {
    await resolveTestCode('''
main(List<String> items) {
  for (String item in items) {
    print(item);
  }
}
''');
    await assertHasAssistAt('tring item', '''
main(List<String> items) {
  for (int i = 0; i < items.length; i++) {
    String item = items[i];
    print(item);
  }
}
''');
  }

  Future<void> test_onFor() async {
    await resolveTestCode('''
main(List<String> items) {
  for (String item in items) {
    print(item);
  }
}
''');
    await assertHasAssistAt('for (String', '''
main(List<String> items) {
  for (int i = 0; i < items.length; i++) {
    String item = items[i];
    print(item);
  }
}
''');
  }

  Future<void> test_usesI() async {
    await resolveTestCode('''
main(List<String> items) {
  for (String item in items) {
    int i = 0;
  }
}
''');
    await assertHasAssistAt('for (String', '''
main(List<String> items) {
  for (int j = 0; j < items.length; j++) {
    String item = items[j];
    int i = 0;
  }
}
''');
  }

  Future<void> test_usesIJ() async {
    await resolveTestCode('''
main(List<String> items) {
  for (String item in items) {
    print(item);
    int i = 0, j = 1;
  }
}
''');
    await assertHasAssistAt('for (String', '''
main(List<String> items) {
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
main(List<String> items) {
  for (String item in items) {
    print(item);
    int i, j, k;
  }
}
''');
    await assertNoAssistAt('for (String');
  }
}
