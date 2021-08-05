// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ImportAddShowTest);
  });
}

@reflectiveTest
class ImportAddShowTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.IMPORT_ADD_SHOW;

  Future<void> test_hasShow() async {
    await resolveTestCode('''
import 'dart:math' show pi;
void f() {
  pi;
}
''');
    await assertNoAssistAt('import ');
  }

  Future<void> test_hasUnresolvedIdentifier() async {
    await resolveTestCode('''
import 'dart:math';
void f(x) {
  pi;
  return x.foo();
}
''');
    await assertHasAssistAt('import ', '''
import 'dart:math' show pi;
void f(x) {
  pi;
  return x.foo();
}
''');
  }

  Future<void> test_onDirective() async {
    await resolveTestCode('''
import 'dart:math';
void f() {
  pi;
  e;
  max(1, 2);
}
''');
    await assertHasAssistAt('import ', '''
import 'dart:math' show e, max, pi;
void f() {
  pi;
  e;
  max(1, 2);
}
''');
  }

  Future<void> test_onUri() async {
    await resolveTestCode('''
import 'dart:math';
void f() {
  pi;
  e;
  max(1, 2);
}
''');
    await assertHasAssistAt('art:math', '''
import 'dart:math' show e, max, pi;
void f() {
  pi;
  e;
  max(1, 2);
}
''');
  }

  Future<void> test_setterOnDirective() async {
    addSource('/home/test/lib/a.dart', r'''
void set setter(int i) {}
''');
    await resolveTestCode('''
import 'a.dart';

void f() {
  setter = 42;
}
''');
    await assertHasAssistAt('import ', '''
import 'a.dart' show setter;

void f() {
  setter = 42;
}
''');
  }

  Future<void> test_unresolvedUri() async {
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
import '/no/such/lib.dart';
''');
    await assertNoAssistAt('import ');
  }

  Future<void> test_unused() async {
    await resolveTestCode('''
import 'dart:math';
''');
    await assertNoAssistAt('import ');
  }
}
