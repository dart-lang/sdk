// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RemoveAsyncTest);
  });
}

@reflectiveTest
class RemoveAsyncTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.removeAsync;

  Future<void> test_closure() async {
    await resolveTestCode('''
void f() {
  () async ^{};
}
''');
    await assertHasAssist('''
void f() {
  () {};
}
''');
  }

  Future<void> test_future() async {
    await resolveTestCode('''
Future<void> test() async^ {}
''');
    await assertHasAssist('''
void test() {}
''');
  }

  Future<void> test_futureOr() async {
    await resolveTestCode('''
import 'dart:async';

FutureOr<void> test()^ async {}
''');
    await assertHasAssist('''
import 'dart:async';

void test() {}
''');
  }

  Future<void> test_futureOr_futureOr() async {
    await resolveTestCode('''
import 'dart:async';

FutureOr<int> test() async ^=> test();
''');
    await assertHasAssist('''
import 'dart:async';

FutureOr<int> test() => test();
''');
  }

  Future<void> test_method() async {
    await resolveTestCode('''
import 'dart:async';

class A {
  FutureOr<void> t^est() async {}
}
''');
    await assertHasAssist('''
import 'dart:async';

class A {
  void test() {}
}
''');
  }

  Future<void> test_void() async {
    await resolveTestCode('''
vo^id test() async {}
''');
    await assertHasAssist('''
void test() {}
''');
  }

  Future<void> test_withAsyncReturn() async {
    await resolveTestCode('''
Future<int> test() async ^=> test();
''');
    await assertHasAssist('''
Future<int> test() => test();
''');
  }

  Future<void> test_withAwait() async {
    await resolveTestCode('''
Future<int> test() async^{
  await 0;
  return 0;
}
''');
    await assertNoAssist();
  }

  Future<void> test_withMixedReturns() async {
    await resolveTestCode('''
Future<int> test() async^{
  if (1 == 1) {
    return test();
  }
  return 0;
}
''');
    await assertHasAssist('''
Future<int> test() {
  if (1 == 1) {
    return test();
  }
  return 0;
}
''');
  }

  Future<void> test_withSyncReturn() async {
    await resolveTestCode('''
Future<int> test() async {^
  return 0;
}
''');
    await assertHasAssist('''
int test() {
  return 0;
}
''');
  }
}
