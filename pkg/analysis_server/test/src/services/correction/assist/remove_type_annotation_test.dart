// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveTypeAnnotationTest);
  });
}

@reflectiveTest
class RemoveTypeAnnotationTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.REMOVE_TYPE_ANNOTATION;

  Future<void> test_classField() async {
    await resolveTestCode('''
class A {
  int v = 1;
}
''');
    await assertHasAssistAt('v = ', '''
class A {
  var v = 1;
}
''');
  }

  Future<void> test_classField_final() async {
    await resolveTestCode('''
class A {
  final int v = 1;
}
''');
    await assertHasAssistAt('v = ', '''
class A {
  final v = 1;
}
''');
  }

  Future<void> test_field_noInitializer() async {
    await resolveTestCode('''
class A {
  int? v;
}
''');
    await assertNoAssistAt('v');
  }

  Future<void> test_instanceCreation_freeStanding() async {
    await resolveTestCode('''
class A {}

void f() {
  A();
}
''');
    await assertNoAssistAt('A();');
  }

  Future<void> test_localVariable() async {
    await resolveTestCode('''
void f() {
  int a = 1, b = 2;
}
''');
    await assertHasAssistAt('int ', '''
void f() {
  var a = 1, b = 2;
}
''');
  }

  Future<void> test_localVariable_const() async {
    await resolveTestCode('''
void f() {
  const int v = 1;
}
''');
    await assertHasAssistAt('int ', '''
void f() {
  const v = 1;
}
''');
  }

  Future<void> test_localVariable_final() async {
    await resolveTestCode('''
void f() {
  final int v = 1;
}
''');
    await assertHasAssistAt('int ', '''
void f() {
  final v = 1;
}
''');
  }

  Future<void> test_localVariable_noInitializer() async {
    await resolveTestCode('''
void f() {
  int v;
}
''');
    await assertNoAssistAt('v;');
  }

  Future<void> test_localVariable_onInitializer() async {
    await resolveTestCode('''
void f() {
  final int v = 1;
}
''');
    await assertNoAssistAt('1;');
  }

  Future<void> test_loopVariable() async {
    await resolveTestCode('''
void f() {
  for(int i = 0; i < 3; i++) {}
}
''');
    await assertHasAssistAt('int ', '''
void f() {
  for(var i = 0; i < 3; i++) {}
}
''');
  }

  Future<void> test_loopVariable_nested() async {
    await resolveTestCode('''
void f() {
  var v = () {
    for (int x in <int>[]) {}
  };
}
''');
    await assertHasAssistAt('int x', '''
void f() {
  var v = () {
    for (var x in <int>[]) {}
  };
}
''');
  }

  Future<void> test_loopVariable_noType() async {
    await resolveTestCode('''
void f() {
  for(var i = 0; i < 3; i++) {}
}
''');
    await assertNoAssistAt('var ');
  }

  Future<void> test_topLevelVariable() async {
    await resolveTestCode('''
int V = 1;
''');
    await assertHasAssistAt('int ', '''
var V = 1;
''');
  }

  Future<void> test_topLevelVariable_final() async {
    await resolveTestCode('''
final int V = 1;
''');
    await assertHasAssistAt('int ', '''
final V = 1;
''');
  }

  Future<void> test_topLevelVariable_noInitializer() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
int v;
''');
    await assertNoAssistAt('v;');
  }

  Future<void> test_topLevelVariable_syntheticName() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
MyType
''');
    await assertNoAssistAt('MyType');
  }
}
