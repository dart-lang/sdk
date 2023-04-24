// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SplitVariableDeclarationTest);
  });
}

@reflectiveTest
class SplitVariableDeclarationTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.SPLIT_VARIABLE_DECLARATION;

  Future<void> test_const() async {
    await resolveTestCode('''
void f() {
  const v = 1;
}
''');
    await assertNoAssistAt('v = 1');
  }

  Future<void> test_final() async {
    await resolveTestCode('''
void f() {
  final v = 1;
}
''');
    await assertNoAssistAt('v = 1');
  }

  Future<void> test_notOneVariable() async {
    await resolveTestCode('''
void f() {
  var v = 1, v2;
}
''');
    await assertNoAssistAt('v = 1');
  }

  Future<void> test_onName() async {
    await resolveTestCode('''
void f() {
  var v = 1;
}
''');
    await assertHasAssistAt('v =', '''
void f() {
  int v;
  v = 1;
}
''');
  }

  Future<void> test_onName_functionStatement_noType() async {
    await resolveTestCode('''
f() => 1;
void g() {
  var v = f();
}
''');
    await assertHasAssistAt('v =', '''
f() => 1;
void g() {
  var v;
  v = f();
}
''');
  }

  Future<void> test_onName_recordType() async {
    await resolveTestCode('''
void f() {
  (int, int) v = (1, 2);
}
''');
    await assertHasAssistAt('v =', '''
void f() {
  (int, int) v;
  v = (1, 2);
}
''');
  }

  Future<void> test_onType() async {
    await resolveTestCode('''
void f() {
  int v = 1;
}
''');
    await assertHasAssistAt('int ', '''
void f() {
  int v;
  v = 1;
}
''');
  }

  @failingTest
  Future<void> test_onType_prefixedByComment() async {
    await resolveTestCode('''
void f() {
  /*comment*/int v = 1;
}
''');
    await assertHasAssistAt('int ', '''
void f() {
  /*comment*/int v;
  v = 1;
}
''');
  }

  Future<void> test_onType_recordType() async {
    await resolveTestCode('''
void f() {
  (int, int) v = (1, 2);
}
''');
    await assertHasAssistAt('int)', '''
void f() {
  (int, int) v;
  v = (1, 2);
}
''');
  }

  Future<void> test_onVar() async {
    await resolveTestCode('''
void f() {
  var v = 1;
}
''');
    await assertHasAssistAt('var ', '''
void f() {
  int v;
  v = 1;
}
''');
  }

  Future<void> test_onVar_recordLiteral() async {
    await resolveTestCode('''
void f() {
  var v = (1, 2);
}
''');
    await assertHasAssistAt('var', '''
void f() {
  (int, int) v;
  v = (1, 2);
}
''');
  }

  Future<void> test_privateType() async {
    newFile('$testPackageLibPath/a.dart', '''
class A {
  _B b => _B();
}
class _B {}
''');

    await resolveTestCode('''
import 'package:test/a.dart';

f(A a) {
  var x = a.b();
}
''');
    await assertNoAssistAt('var ');
  }
}
