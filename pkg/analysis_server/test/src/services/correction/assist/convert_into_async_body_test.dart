// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/assist.dart';
import 'package:analyzer_plugin/utilities/assist/assist.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'assist_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(ConvertIntoAsyncBodyTest);
  });
}

@reflectiveTest
class ConvertIntoAsyncBodyTest extends AssistProcessorTest {
  @override
  AssistKind get kind => DartAssistKind.CONVERT_INTO_ASYNC_BODY;

  Future<void> test_async() async {
    await resolveTestCode('''
import 'dart:async';
Future<String> f() async => '';
''');
    await assertNoAssistAt('=>');
  }

  Future<void> test_asyncStar() async {
    await resolveTestCode('''
import 'dart:async';
Stream<String> f() async* {}
''');
    await assertNoAssistAt('{}');
  }

  Future<void> test_closure() async {
    await resolveTestCode('''
void h() {
  f(() => 123);
}
f(g) {}
''');
    await assertNoAssistAt('=>');
  }

  Future<void> test_closure_assignment() async {
    await resolveTestCode('''
void f() {
  var c = () {};
}
''');
    await assertNoAssistAt('{}');
  }

  Future<void> test_closure_future() async {
    await resolveTestCode('''
import 'dart:async';

void g(Future<int> Function() fun) {}

void f() {
  g(() => Future.value(1));
}
''');
    await assertNoAssistAt('=>');
  }

  Future<void> test_closure_futureOr() async {
    await resolveTestCode('''
import 'dart:async';

void g(FutureOr<int> Function() fun) {}

void f() {
  g(() => 1);
}
''');
    await assertNoAssistAt('=>');
  }

  Future<void> test_closure_int() async {
    await resolveTestCode('''
void g(int Function() fun) {}

void f() {
  g(() => 1);
}
''');
    await assertNoAssistAt('=>');
  }

  Future<void> test_closure_void() async {
    await resolveTestCode('''
void g(void Function() fun) {
}

void f() {
  g(() {});
}
''');
    await assertNoAssistAt('{}');
  }

  Future<void> test_constructor() async {
    await resolveTestCode('''
class C {
  C() {}
}
''');
    await assertNoAssistAt('{}');
  }

  Future<void> test_function() async {
    await resolveTestCode('''
String f() => '';
''');
    await assertHasAssistAt('=>', '''
Future<String> f() async => '';
''');
  }

  Future<void> test_function_local() async {
    await resolveTestCode('''
void g() {
  String f() => '';
}
''');
    await assertHasAssistAt('=>', '''
void g() {
  Future<String> f() async => '';
}
''');
  }

  Future<void> test_function_returnType_future() async {
    await resolveTestCode(r'''
Future<int> f() => Future.value(0);
''');

    await assertHasAssistAt('=>', r'''
Future<int> f() async => Future.value(0);
''');
  }

  Future<void> test_function_returnType_futureOr() async {
    await resolveTestCode(r'''
import 'dart:async';

FutureOr<int> f() => 0;
''');

    await assertHasAssistAt('=>', r'''
import 'dart:async';

Future<int> f() async => 0;
''');
  }

  Future<void> test_getter_expression_noSpace() async {
    await resolveTestCode('''
class C {
  int get g=>0;
}
''');
    await assertHasAssistAt('get g', '''
class C {
  Future<int> get g async =>0;
}
''');
  }

  Future<void> test_inBody_block() async {
    await resolveTestCode('''
class C {
  void foo() {
    print(42);
  }
}
''');
    await assertNoAssistAt('print');
  }

  Future<void> test_inBody_expression() async {
    await resolveTestCode('''
class C {
  void foo() => print(42);
}
''');
    await assertNoAssistAt('print');
  }

  Future<void> test_method() async {
    await resolveTestCode('''
class C {
  int m() { return 0; }
}
''');
    await assertHasAssistAt('{ return', '''
class C {
  Future<int> m() async { return 0; }
}
''');
  }

  Future<void> test_method_abstract() async {
    await resolveTestCode('''
abstract class C {
  int m();
}
''');
    await assertNoAssist();
  }

  Future<void> test_method_noReturnType() async {
    await resolveTestCode('''
class C {
  m() { return 0; }
}
''');
    await assertHasAssistAt('{ return', '''
class C {
  m() async { return 0; }
}
''');
  }

  Future<void> test_sync() async {
    // This code is erroneous; the test ensures there is no error thrown when
    // computing assists.
    verifyNoTestUnitErrors = false;
    await resolveTestCode('''
Iterable<String> f() sync {}
''');
    await assertNoAssistAt('{}');
  }

  Future<void> test_syncStar() async {
    await resolveTestCode('''
Iterable<String> f() sync* {}
''');
    await assertNoAssistAt('{}');
  }
}
