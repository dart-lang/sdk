// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertToIfCaseStatementTest);
  });
}

@reflectiveTest
class ConvertToIfCaseStatementTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_TO_IF_CASE_STATEMENT;

  Future<void> test_isType() async {
    await resolveTestCode('''
void f(A a) {
  var y = a.x;
  if (y is List<int>) {}
}

class A {
  Object? x;
}
''');
    await assertHasAssistAt('if', '''
void f(A a) {
  if (a.x case List<int> y) {}
}

class A {
  Object? x;
}
''');
  }

  Future<void> test_isType_final() async {
    await resolveTestCode('''
void f(A a) {
  final y = a.x;
  if (y is int) {}
}

class A {
  Object? x;
}
''');
    await assertHasAssistAt('if', '''
void f(A a) {
  if (a.x case final int y) {}
}

class A {
  Object? x;
}
''');
  }

  Future<void> test_isType_hasReference_afterIf() async {
    await resolveTestCode('''
void f(A a) {
  var y = a.x;
  if (y is int) {}
  y;
}

class A {
  Object? x;
}
''');
    await assertNoAssistAt('if');
  }

  Future<void> test_isType_hasReference_inElse() async {
    await resolveTestCode('''
void f(A a) {
  var y = a.x;
  if (y is int) {} else {
    y;
  }
}

class A {
  Object? x;
}
''');
    await assertNoAssistAt('if');
  }

  Future<void> test_isType_language219() async {
    await resolveTestCode('''
// @dart = 2.19
void f(A a) {
  var y = a.x;
  if (y is List<int>) {}
}

class A {
  Object? x;
}
''');
    await assertNoAssistAt('if');
  }

  Future<void> test_isType_previousStatement_absent() async {
    await resolveTestCode('''
void f(Object? x) {
  if (x is int) {}
}
''');
    await assertNoAssistAt('if');
  }

  Future<void> test_notEqNull() async {
    await resolveTestCode('''
void f(A a) {
  var y = a.x;
  if (y != null) {}
}

class A {
  int? x;
}
''');
    await assertHasAssistAt('if', '''
void f(A a) {
  if (a.x case var y?) {}
}

class A {
  int? x;
}
''');
  }

  Future<void> test_notEqNull_final() async {
    await resolveTestCode('''
void f(A a) {
  final y = a.x;
  if (y != null) {}
}

class A {
  int? x;
}
''');
    await assertHasAssistAt('if', '''
void f(A a) {
  if (a.x case final y?) {}
}

class A {
  int? x;
}
''');
  }

  Future<void> test_notEqNull_hasReference_afterIf() async {
    await resolveTestCode('''
void f(A a) {
  final y = a.x;
  if (y != null) {}
  y;
}

class A {
  int? x;
}
''');
    await assertNoAssistAt('if');
  }

  Future<void> test_notEqNull_hasReference_inElse() async {
    await resolveTestCode('''
void f(A a) {
  final y = a.x;
  if (y != null) {} else {
    y;
  }
}

class A {
  int? x;
}
''');
    await assertNoAssistAt('if');
  }

  Future<void> test_notEqNull_previousStatement_absent() async {
    await resolveTestCode('''
void f(int? x) {
  if (x != null) {}
}
''');
    await assertNoAssistAt('if');
  }

  Future<void> test_notEqNull_previousStatement_multipleDeclarations() async {
    await resolveTestCode('''
void f(A a) {
  final x = a.x, x2 = 0;
  if (x != null) {}
}

class A {
  int? x;
}
''');
    await assertNoAssistAt('if');
  }

  Future<void> test_notEqNull_previousStatement_notDeclaration() async {
    await resolveTestCode('''
void f(int? x) {
  x;
  if (x != null) {}
}
''');
    await assertNoAssistAt('if');
  }
}
