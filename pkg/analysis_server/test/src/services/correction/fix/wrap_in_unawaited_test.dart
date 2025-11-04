// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:linter/src/lint_names.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'fix_processor.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(WrapDiscardedFutureInUnawaitedTest);
    defineReflectiveTests(WrapInUnawaitedTest);
  });
}

@reflectiveTest
class WrapDiscardedFutureInUnawaitedTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.wrapInUnawaited;

  @override
  String get lintCode => LintNames.discarded_futures;

  Future<void> test_expressionStatement() async {
    await resolveTestCode('''
void f() {
  g();
}

Future<void> g() async { }
''');
    await assertHasFix('''
import 'dart:async';

void f() {
  unawaited(g());
}

Future<void> g() async { }
''');
  }

  Future<void> test_functionExpressionInvocation() async {
    await resolveTestCode('''
void f() {
  () async {
    await g();
  }();
}

Future<void> g() async { }
''');
    await assertHasFix('''
import 'dart:async';

void f() {
  unawaited(() async {
    await g();
  }());
}

Future<void> g() async { }
''');
  }

  Future<void> test_futureOr() async {
    await resolveTestCode('''
import 'dart:async';

FutureOr<void> g() async { }

void f() {
  g();
}
''');
    await assertHasFix('''
import 'dart:async';

FutureOr<void> g() async { }

void f() {
  unawaited(g());
}
''');
  }
}

@reflectiveTest
class WrapInUnawaitedTest extends FixProcessorLintTest {
  @override
  FixKind get kind => DartFixKind.wrapInUnawaited;

  @override
  String get lintCode => LintNames.unawaited_futures;

  Future<void> test_cascade_after() async {
    await resolveTestCode('''
class A {
  Future<void> m() async {}
}

Future<void> foo(A a) async {
  a.m()..hashCode;
}
''');
    await assertNoFix();
  }

  Future<void> test_cascadeExpression() async {
    await resolveTestCode('''
class C {
  Future<String> something() {
    return Future.value('hello');
  }
}

void main() async {
  C()..something();
}
''');
    await assertNoFix();
  }

  Future<void> test_cascadeExpression_getter() async {
    await resolveTestCode('''
class C {
  Future<String> get something {
    return Future.value('hello');
  }
}

void f(C Function() fn) async {
  fn()..something;
}
''');
    await assertNoFix();
  }

  Future<void> test_expressionStatement() async {
    await resolveTestCode('''
Future<void> f() async {
  g();
}

Future<void> g() async { }
''');
    await assertHasFix('''
import 'dart:async';

Future<void> f() async {
  unawaited(g());
}

Future<void> g() async { }
''');
  }

  Future<void> test_expressionStatement_prefixed() async {
    newFile('$testPackageLibPath/g.dart', '''
Future<void> g() async { }
''');

    await resolveTestCode('''
import 'g.dart' as g_lib;

Future<void> f() async {
  g_lib.g();
}
''');
    await assertHasFix('''
import 'dart:async';

import 'g.dart' as g_lib;

Future<void> f() async {
  unawaited(g_lib.g());
}
''');
  }

  Future<void> test_expressionStatement_prefixedImport() async {
    await resolveTestCode('''
import 'dart:async' as dart_async;

dart_async.Future<void> f() async {
  g();
}

dart_async.Future<void> g() async { }
''');
    await assertHasFix('''
import 'dart:async' as dart_async;

dart_async.Future<void> f() async {
  dart_async.unawaited(g());
}

dart_async.Future<void> g() async { }
''');
  }

  Future<void> test_expressionStatement_prefixedTarget() async {
    newFile('$testPackageLibPath/g.dart', '''
class C {
  static Future<void> g() async { }
}
''');

    await resolveTestCode('''
import 'g.dart' as g_lib;

Future<void> f() async {
  g_lib.C.g();
}
''');
    await assertHasFix('''
import 'dart:async';

import 'g.dart' as g_lib;

Future<void> f() async {
  unawaited(g_lib.C.g());
}
''');
  }

  Future<void> test_expressionStatement_target() async {
    await resolveTestCode('''
class C {
  Future<void> g() async { }
}

Future<void> f() async {
  var c = C();
  c.g();
}
''');
    await assertHasFix('''
import 'dart:async';

class C {
  Future<void> g() async { }
}

Future<void> f() async {
  var c = C();
  unawaited(c.g());
}
''');
  }

  Future<void> test_nullableFuture() async {
    await resolveTestCode('''
Future<void> f() async {
  g();
}

Future<void>? g() async { }
''');
    await assertHasFix('''
import 'dart:async';

Future<void> f() async {
  unawaited(g());
}

Future<void>? g() async { }
''');
  }

  Future<void> test_subTypeOfFuture() async {
    await resolveTestCode('''
abstract class MyFuture implements Future<void> {}

void f(MyFuture myFuture) async {
  myFuture;
}
''');
    await assertHasFix('''
import 'dart:async';

abstract class MyFuture implements Future<void> {}

void f(MyFuture myFuture) async {
  unawaited(myFuture);
}
''');
  }
}
