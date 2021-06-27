// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ReplaceConditionalWithIfElseTest);
  });
}

@reflectiveTest
class ReplaceConditionalWithIfElseTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.REPLACE_CONDITIONAL_WITH_IF_ELSE;

  Future<void> test_assignment() async {
    await resolveTestCode('''
void f(bool c) {
  var v;
  v = c ? 111 : 222;
}
''');
    // on conditional
    await assertHasAssistAt('11 :', '''
void f(bool c) {
  var v;
  if (c) {
    v = 111;
  } else {
    v = 222;
  }
}
''');
    // on variable
    await assertHasAssistAt('v =', '''
void f(bool c) {
  var v;
  if (c) {
    v = 111;
  } else {
    v = 222;
  }
}
''');
  }

  Future<void> test_noEnclosingStatement() async {
    await resolveTestCode('''
var v = true ? 111 : 222;
''');
    await assertNoAssistAt('? 111');
  }

  Future<void> test_notConditional() async {
    await resolveTestCode('''
void f() {
  var v = 42;
}
''');
    await assertNoAssistAt('v = 42');
  }

  Future<void> test_return() async {
    await resolveTestCode('''
int f(bool c) {
  return c ? 111 : 222;
}
''');
    await assertHasAssistAt('return ', '''
int f(bool c) {
  if (c) {
    return 111;
  } else {
    return 222;
  }
}
''');
  }

  Future<void> test_variableDeclaration_final() async {
    await resolveTestCode('''
void f(bool c) {
  final a = c ? 111 : 222;
}
''');
    await assertHasAssistAt('11 :', '''
void f(bool c) {
  final int a;
  if (c) {
    a = 111;
  } else {
    a = 222;
  }
}
''');
  }

  Future<void> test_variableDeclaration_oneOfMany() async {
    await resolveTestCode('''
void f(bool c) {
  int a = 1, vvv = c ? 111 : 222, b = 2;
}
''');
    await assertHasAssistAt('11 :', '''
void f(bool c) {
  int a = 1, vvv, b = 2;
  if (c) {
    vvv = 111;
  } else {
    vvv = 222;
  }
}
''');
  }

  Future<void> test_variableDeclaration_type() async {
    await resolveTestCode('''
void f(bool c) {
  num a = c ? 111 : 222;
}
''');
    await assertHasAssistAt('11 :', '''
void f(bool c) {
  num a;
  if (c) {
    a = 111;
  } else {
    a = 222;
  }
}
''');
  }

  Future<void> test_variableDeclaration_type_final() async {
    await resolveTestCode('''
void f(bool c) {
  final num a = c ? 111 : 222;
}
''');
    await assertHasAssistAt('11 :', '''
void f(bool c) {
  final num a;
  if (c) {
    a = 111;
  } else {
    a = 222;
  }
}
''');
  }

  Future<void> test_variableDeclaration_type_late() async {
    writeTestPackageConfig(languageVersion: '2.12.0');
    await resolveTestCode('''
void f(bool c) {
  late num a = c ? 111 : 222;
}
''');
    await assertHasAssistAt('11 :', '''
void f(bool c) {
  late num a;
  if (c) {
    a = 111;
  } else {
    a = 222;
  }
}
''');
  }

  Future<void> test_variableDeclaration_var() async {
    await resolveTestCode('''
void f(bool c) {
  var a = c ? 111 : 222;
}
''');
    await assertHasAssistAt('11 :', '''
void f(bool c) {
  int a;
  if (c) {
    a = 111;
  } else {
    a = 222;
  }
}
''');
  }

  Future<void> test_variableDeclaration_var_late() async {
    writeTestPackageConfig(languageVersion: '2.12.0');
    await resolveTestCode('''
void f(bool c) {
  late var a = c ? 111 : 222;
}
''');
    await assertHasAssistAt('11 :', '''
void f(bool c) {
  late int a;
  if (c) {
    a = 111;
  } else {
    a = 222;
  }
}
''');
  }
}
