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
  AssistKind get kind => DartAssistKind.removeTypeAnnotation;

  Future<void> test_classField() async {
    await resolveTestCode('''
class A {
  int ^v = 1;
}
''');
    await assertHasAssist('''
class A {
  var v = 1;
}
''');
  }

  Future<void> test_classField_final() async {
    await resolveTestCode('''
class A {
  final int ^v = 1;
}
''');
    await assertHasAssist('''
class A {
  final v = 1;
}
''');
  }

  Future<void> test_field_noInitializer() async {
    await resolveTestCode('''
class A {
  int? ^v;
}
''');
    await assertNoAssist();
  }

  Future<void> test_generic_instanceCreation_withoutArguments() async {
    await resolveTestCode('''
C<int> ^c = C();
class C<T> {}
''');
    await assertHasAssist('''
var c = C<int>();
class C<T> {}
''');
  }

  Future<void> test_generic_listLiteral() async {
    await resolveTestCode('''
List<int> ^l = [];
''');
    await assertHasAssist('''
var l = <int>[];
''');
  }

  Future<void> test_generic_setLiteral_ambiguous() async {
    await resolveTestCode('''
Set f() {
  ^Set s = {};
  return s;
}
''');
    await assertNoAssist();
  }

  Future<void> test_generic_setLiteral_cascade() async {
    await resolveTestCode('''
Set<String> ^s = {}..addAll([]);
''');
    await assertHasAssist('''
var s = <String>{}..addAll([]);
''');
  }

  Future<void> test_instanceCreation_freeStanding() async {
    await resolveTestCode('''
class A {}

void f() {
  ^A();
}
''');
    await assertNoAssist();
  }

  Future<void> test_localVariable() async {
    await resolveTestCode('''
void f() {
  ^int a = 1, b = 2;
}
''');
    await assertHasAssist('''
void f() {
  var a = 1, b = 2;
}
''');
  }

  Future<void> test_localVariable_const() async {
    await resolveTestCode('''
void f() {
  const ^int v = 1;
}
''');
    await assertHasAssist('''
void f() {
  const v = 1;
}
''');
  }

  Future<void> test_localVariable_final() async {
    await resolveTestCode('''
void f() {
  final ^int v = 1;
}
''');
    await assertHasAssist('''
void f() {
  final v = 1;
}
''');
  }

  Future<void> test_localVariable_noInitializer() async {
    await resolveTestCode('''
void f() {
  int ^v;
}
''');
    await assertNoAssist();
  }

  Future<void> test_localVariable_onInitializer() async {
    await resolveTestCode('''
void f() {
  final int v = ^1;
}
''');
    await assertNoAssist();
  }

  Future<void> test_loopVariable() async {
    await resolveTestCode('''
void f() {
  for(^int i = 0; i < 3; i++) {}
}
''');
    await assertHasAssist('''
void f() {
  for(var i = 0; i < 3; i++) {}
}
''');
  }

  Future<void> test_loopVariable_nested() async {
    await resolveTestCode('''
void f() {
  var v = () {
    for (^int x in <int>[]) {}
  };
}
''');
    await assertHasAssist('''
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
  for(v^ar i = 0; i < 3; i++) {}
}
''');
    await assertNoAssist();
  }

  Future<void> test_topLevelVariable() async {
    await resolveTestCode('''
^int V = 1;
''');
    await assertHasAssist('''
var V = 1;
''');
  }

  Future<void> test_topLevelVariable_final() async {
    await resolveTestCode('''
final i^nt V = 1;
''');
    await assertHasAssist('''
final V = 1;
''');
  }

  Future<void> test_topLevelVariable_noInitializer() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
int v^;
''');
    await assertNoAssist();
  }

  Future<void> test_topLevelVariable_syntheticName() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
MyType^
''');
    await assertNoAssist();
  }
}
