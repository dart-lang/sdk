// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AddAsyncTest);
    defineReflectiveTests(DiscardedFuturesTest);
  });
}

@reflectiveTest
class AddAsyncTest extends FixProcessorTest {
  @override
  FixKind get kind => DartFixKind.ADD_ASYNC;

  Future<void> test_asyncFor() async {
    await resolveTestCode('''
void f(Stream<String> names) {
  await for (String name in names) {
    print(name);
  }
}
''');
    await assertHasFix('''
Future<void> f(Stream<String> names) async {
  await for (String name in names) {
    print(name);
  }
}
''');
  }

  Future<void> test_blockFunctionBody_function() async {
    await resolveTestCode('''
foo() {}
f() {
  await foo();
}
''');
    await assertHasFix('''
foo() {}
f() async {
  await foo();
}
''');
  }

  Future<void> test_blockFunctionBody_getter() async {
    await resolveTestCode('''
int get foo => null;
int f() {
  await foo;
  return 1;
}
''');
    await assertHasFix(
      '''
int get foo => null;
Future<int> f() async {
  await foo;
  return 1;
}
''',
      errorFilter: (error) {
        return error.errorCode ==
            CompileTimeErrorCode.UNDEFINED_IDENTIFIER_AWAIT;
      },
    );
  }

  Future<void> test_closure() async {
    await resolveTestCode('''
void takeFutureCallback(Future callback()) {}

void doStuff() => takeFutureCallback(() => await 1);
''');
    await assertHasFix(
      '''
void takeFutureCallback(Future callback()) {}

void doStuff() => takeFutureCallback(() async => await 1);
''',
      errorFilter: (error) {
        return error.errorCode ==
            CompileTimeErrorCode.UNDEFINED_IDENTIFIER_AWAIT;
      },
    );
  }

  Future<void> test_expressionFunctionBody() async {
    await resolveTestCode('''
foo() {}
f() => await foo();
''');
    await assertHasFix('''
foo() {}
f() async => await foo();
''');
  }

  Future<void> test_futureOrString() async {
    await resolveTestCode('''
Future<String> f() {
  if (1 == 2) {
    return '';
  }
  return Future.value('');
}
''');
    await assertHasFix('''
Future<String> f() async {
  if (1 == 2) {
    return '';
  }
  return Future.value('');
}
''');
  }

  Future<void> test_futureString_closure() async {
    await resolveTestCode('''
void f(Future<String> Function() p) async {}

void g() => f(() => '');
''');
    await assertHasFix('''
void f(Future<String> Function() p) async {}

void g() => f(() async => '');
''');
  }

  Future<void> test_futureString_function() async {
    await resolveTestCode('''
Future<String> f() {
  return '';
}
''');
    await assertHasFix('''
Future<String> f() async {
  return '';
}
''');
  }

  Future<void> test_futureString_innerClosure_closure() async {
    await resolveTestCode('''
void f(Future<String> Function() p) async {}

void g() => f(() => () => '');
''');
    await assertNoFix();
  }

  Future<void> test_futureString_innerClosure_functionBody() async {
    await resolveTestCode('''
Future<int> f() {
  () => '';
  return 0;
}
''');
    await assertHasFix('''
Future<int> f() async {
  () => '';
  return 0;
}
''');
  }

  Future<void> test_futureString_innerClosureCall_closure() async {
    await resolveTestCode('''
void f(Future<String> Function() p) async {}

void g() => f(() => (() => '')());
''');
    await assertHasFix('''
void f(Future<String> Function() p) async {}

void g() => f(() async => (() => '')());
''');
  }

  Future<void> test_futureString_innerClosureCall_functionBody() async {
    await resolveTestCode('''
Future<String> f() {
  return (() => '')();
}
''');
    await assertHasFix('''
Future<String> f() async {
  return (() => '')();
}
''');
  }

  Future<void> test_futureString_innerFunction_closure() async {
    await resolveTestCode('''
void f(Future<int> Function() p) async {}

void g() => f(() => () {
  return '';
});
''');
    await assertNoFix();
  }

  Future<void> test_futureString_innerFunction_functionBody() async {
    await resolveTestCode('''
Future<String> f() {
  int g() {
    return 0;
  }
  g();
  return '';
}
''');
    await assertHasFix('''
Future<String> f() async {
  int g() {
    return 0;
  }
  g();
  return '';
}
''');
  }

  Future<void> test_futureString_innerFunctionCall_closure() async {
    await resolveTestCode('''
void f(Future<String> Function() p) async {}

void g() => f(() => (() {
  return '';
})());
''');
    await assertHasFix('''
void f(Future<String> Function() p) async {}

void g() => f(() async => (() {
  return '';
})());
''');
  }

  Future<void> test_futureString_innerFunctionCall_functionBody() async {
    await resolveTestCode('''
Future<String> f() {
  String g() {
    return '';
  }
  return g();
}
''');
    await assertHasFix('''
Future<String> f() async {
  String g() {
    return '';
  }
  return g();
}
''');
  }

  Future<void> test_futureString_int_closure() async {
    await resolveTestCode('''
void f(Future<String> Function() p) async {}

void g() => f(() => 0);
''');
    await assertNoFix();
  }

  Future<void> test_futureString_int_function() async {
    await resolveTestCode('''
Future<String> f() {
  return 0;
}
''');
    await assertNoFix();
  }

  Future<void> test_futureString_int_method() async {
    await resolveTestCode('''
class C {
  Future<String> f() {
    return 0;
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_futureString_method() async {
    await resolveTestCode('''
class C {
  Future<String> f() {
    return '';
  }
}
''');
    await assertHasFix('''
class C {
  Future<String> f() async {
    return '';
  }
}
''');
  }

  Future<void> test_localFunction() async {
    await resolveTestCode('''
void f() async {
  Future<void> g() {}
  await g();
}
''');
    await assertHasFix('''
void f() async {
  Future<void> g() async {}
  await g();
}
''');
  }

  Future<void> test_missingReturn_method_notVoid() async {
    await resolveTestCode('''
class C {
  Future<int> m() {
    print('');
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_missingReturn_method_notVoid_inherited() async {
    await resolveTestCode('''
abstract class A {
  Future<int> foo();
}

class B implements A {
  foo() {
  print('');
  }
}
''');
    await assertNoFix();
  }

  Future<void> test_missingReturn_method_void() async {
    await resolveTestCode('''
class C {
  Future<void> m() {
    print('');
  }
}
''');
    await assertHasFix('''
class C {
  Future<void> m() async {
    print('');
  }
}
''');
  }

  Future<void> test_missingReturn_method_void_inherited() async {
    await resolveTestCode('''
abstract class A {
  Future<void> foo();
}

class B implements A {
  foo() {
  print('');
  }
}
''');
    await assertHasFix('''
abstract class A {
  Future<void> foo();
}

class B implements A {
  foo() async {
  print('');
  }
}
''');
  }

  Future<void> test_missingReturn_notVoid() async {
    await resolveTestCode('''
Future<int> f() {
  print('');
}
''');
    await assertNoFix();
  }

  Future<void> test_missingReturn_topLevel_notVoid() async {
    await resolveTestCode('''
Future<int> f() {
  print('');
}
''');
    await assertNoFix();
  }

  Future<void> test_missingReturn_topLevel_void() async {
    await resolveTestCode('''
Future<void> f() {
  print('');
}
''');
    await assertHasFix('''
Future<void> f() async {
  print('');
}
''');
  }

  Future<void> test_missingReturn_void() async {
    await resolveTestCode('''
Future<void> f() {
  print('');
}
''');
    await assertHasFix('''
Future<void> f() async {
  print('');
}
''');
  }

  Future<void> test_nullFunctionBody() async {
    await resolveTestCode('''
var F = await;
''');
    await assertNoFix();
  }

  Future<void> test_returnFuture_alreadyFuture() async {
    await resolveTestCode('''
foo() {}
Future<int> f() {
  await foo();
  return 42;
}
''');
    await assertHasFix(
      '''
foo() {}
Future<int> f() async {
  await foo();
  return 42;
}
''',
      errorFilter: (error) {
        return error.errorCode == CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT;
      },
    );
  }

  Future<void> test_returnFuture_dynamic() async {
    await resolveTestCode('''
foo() {}
dynamic f() {
  await foo();
  return 42;
}
''');
    await assertHasFix('''
foo() {}
dynamic f() async {
  await foo();
  return 42;
}
''');
  }

  Future<void> test_returnFuture_nonFuture() async {
    await resolveTestCode('''
foo() {}
int f() {
  await foo();
  return 42;
}
''');
    await assertHasFix('''
foo() {}
Future<int> f() async {
  await foo();
  return 42;
}
''');
  }

  Future<void> test_returnFuture_noType() async {
    await resolveTestCode('''
foo() {}
f() {
  await foo();
  return 42;
}
''');
    await assertHasFix('''
foo() {}
f() async {
  await foo();
  return 42;
}
''');
  }
}

@reflectiveTest
class DiscardedFuturesTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.ADD_ASYNC;

  @override
  String get lintCode => LintNames.discarded_futures;

  Future<void> test_discardedFuture() async {
    await resolveTestCode('''
void f() {
  g();
}

Future<void> g() async { }
''');
    await assertHasFix('''
Future<void> f() async {
  g();
}

Future<void> g() async { }
''');
  }
}
