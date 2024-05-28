// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/error/analyzer_error_code.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../rule_test_support.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AvoidCatchesWithoutOnClausesTest);
  });
}

@reflectiveTest
class AvoidCatchesWithoutOnClausesTest extends LintRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  List<AnalyzerErrorCode> get ignoredErrorCodes =>
      [WarningCode.UNUSED_ELEMENT, WarningCode.UNUSED_LOCAL_VARIABLE];

  @override
  String get lintRule => 'avoid_catches_without_on_clauses';

  test_hasOnClause() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} on Exception catch (e) {
    print(e);
  }
}
''');
  }

  test_missingOnClause() async {
    await assertDiagnostics(r'''
void f() {
  try {} catch (e) {}
}
''', [
      lint(20, 5),
    ]);
  }

  test_missingOnClause_nonRelevantUse() async {
    await assertDiagnostics(r'''
void f() {
  try {} catch (e) {
    print(e);
  }
}
''', [
      lint(20, 5),
    ]);
  }

  test_missingOnClause_rethrow() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} catch (e) {
    rethrow;
  }
}
''');
  }

  test_missingOnClause_unrelatedRethrow() async {
    await assertDiagnostics(r'''
void f() {
  try {} catch (e) {
    try {} on Exception catch (e) {
      print(e);
      rethrow;
    }
  }
}
''', [
      lint(20, 5),
    ]);
  }

  test_missingOnClause_unrelatedRethrow_inNestedFunction() async {
    await assertDiagnostics(r'''
void f() {
  try {} catch (e) {
    void g() {
      try {} on Exception catch (e) {
        print(e);
        rethrow;
      }
    }
  }
}
''', [
      lint(20, 5),
    ]);
  }

  test_missingOnClause_usedInCompleter_completeError() async {
    await assertNoDiagnostics(r'''
import 'dart:async';
void f(Completer<void> completer) {
  try {} catch (e) {
    completer.completeError(e);
  }
}
''');
  }

  test_missingOnClause_usedInFlutterError_reportError() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/foundation.dart';
void f() {
  try {} catch (e) {
    FlutterError.reportError(FlutterErrorDetails(exception: e));
  }
}
''');
  }

  test_missingOnClause_usedInFuture_error() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} catch (e) {
    Future.error(e);
  }
}
''');
  }

  test_missingOnClause_usedInNeverReturningFunction() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} catch (e) {
    fail(e);
  }
}
Never fail(Object e) => throw e;
''');
  }

  test_missingOnClause_usedInNeverReturningFunctionExpression() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} catch (e) {
    (fail)(e);
  }
}
Never fail(Object e) => throw e;
''');
  }

  test_missingOnClause_usedInThrownCascadedFunctionInvocation() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} catch (e) {
    throw wrapIt(e)..add(7);
  }
}
List<Object> wrapIt(Object e) => [e];
''');
  }

  test_missingOnClause_usedInThrownFunctionInvocation() async {
    await assertNoDiagnostics(r'''
void f() {
  try {} catch (e) {
    throw wrapIt(e);
  }
}
Object wrapIt(Object e) => e;
''');
  }
}
